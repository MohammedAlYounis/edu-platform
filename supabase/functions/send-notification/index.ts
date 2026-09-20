import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { create, getNumericDate } from 'https://deno.land/x/djwt@v3.0.2/mod.ts';

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function getServiceAccount(): ServiceAccount {
  const raw = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
  if (!raw) throw new Error('FIREBASE_SERVICE_ACCOUNT is not configured');
  const account = JSON.parse(raw) as ServiceAccount;
  if (!account.project_id || !account.client_email || !account.private_key) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT is missing required fields');
  }
  return account;
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '');
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

async function getAccessToken(account: ServiceAccount): Promise<string> {
  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(account.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const jwt = await create(
    { alg: 'RS256', typ: 'JWT' },
    {
      iss: account.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      exp: getNumericDate(3600),
      iat: getNumericDate(0),
    },
    key,
  );
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body:
      `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const data = await response.json();
  if (!data.access_token) {
    throw new Error(`OAuth token exchange failed: ${JSON.stringify(data)}`);
  }
  return data.access_token;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      return json({ error: 'Unauthorized' }, 401);
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );
    const { data: { user }, error: userError } =
      await supabaseAdmin.auth.getUser(authHeader.substring(7));
    if (userError || !user) return json({ error: 'Unauthorized' }, 401);

    const { data: profile, error: profileError } = await supabaseAdmin
      .from('profiles')
      .select('role, is_active')
      .eq('id', user.id)
      .maybeSingle();
    if (profileError || profile?.role !== 'admin' || profile.is_active !== true) {
      return json({ error: 'Forbidden' }, 403);
    }

    const { title, body, type, target_type, target_id } = await req.json();
    if (typeof title !== 'string' || !title.trim() ||
        typeof body !== 'string' || !body.trim()) {
      return json({ error: 'title and body are required' }, 400);
    }

    let deviceQuery = supabaseAdmin.from('user_devices').select('fcm_token, user_id');
    if (target_type === 'student' && target_id) {
      deviceQuery = deviceQuery.eq('user_id', target_id);
    } else if (target_type === 'subject' && target_id) {
      const { data: students, error: studentsError } = await supabaseAdmin
        .from('profiles')
        .select('id')
        .eq('role', 'student')
        .eq('is_active', true);
      if (studentsError) throw studentsError;
      const ids = (students ?? []).map((student: { id: string }) => student.id);
      if (!ids.length) return json({ sent: 0, reason: 'no students' });
      deviceQuery = deviceQuery.in('user_id', ids);
    }

    const { data: devices, error } = await deviceQuery;
    if (error) throw error;
    if (!devices?.length) return json({ sent: 0, reason: 'no devices' });

    const account = getServiceAccount();
    const accessToken = await getAccessToken(account);
    let sent = 0;
    let failed = 0;
    for (const device of devices) {
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            message: {
              token: device.fcm_token,
              notification: { title, body },
              data: { type: type ?? '', id: target_id ?? '' },
            },
          }),
        },
      );
      if (response.ok) sent++;
      else failed++;
    }
    return json({ sent, failed });
  } catch (error) {
    return json({ error: String(error) }, 500);
  }
});
