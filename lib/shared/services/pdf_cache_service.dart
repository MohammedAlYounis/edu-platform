import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/network/supabase_client_provider.dart';

final pdfCacheServiceProvider = Provider<PdfCacheService>((ref) {
  return PdfCacheService(ref.watch(supabaseClientProvider));
});

/// يحمّل ملف PDF من bucket معيّن (lessons/exams) عبر الجلسة المصادَق عليها،
/// ويخزّنه محليًا لتجنّب إعادة التنزيل عند كل فتح — بند 17/18 في التصميم:
/// "Local Storage / Cache... لا تستخدم التخزين المحلي كقاعدة البيانات الأساسية".
/// إن لم توجد نسخة محلية أو فشل التنزيل، التطبيق يعمل بشكل طبيعي (لا اعتماد إجباري).
class PdfCacheService {
  final SupabaseClient _client;
  const PdfCacheService(this._client);

  Future<File> getLocalFile({
    required String bucket,
    required String storagePath,
  }) async {
    final cacheDir = await getApplicationCacheDirectory();
    final hash = crypto.sha1.convert(storagePath.codeUnits).toString();
    final ext = storagePath.split('.').last;
    final localFile = File('${cacheDir.path}/$hash.$ext');

    if (await localFile.exists()) {
      return localFile;
    }

    final Uint8List bytes = await _client.storage.from(bucket).download(storagePath);
    await localFile.writeAsBytes(bytes, flush: true);
    return localFile;
  }

  Future<void> clearCache() async {
    final cacheDir = await getApplicationCacheDirectory();
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
    }
  }
}
