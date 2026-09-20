import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/localization/localization_extension.dart';
import '../../../../shared/widgets/language_switch_button.dart';
import '../../application/auth_notifier.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final form = FormGroup({
    'email': FormControl<String>(
      validators: [Validators.required, Validators.email],
    ),
  });

  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (form.invalid) {
      form.markAllAsTouched();
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(authNotifierProvider.notifier).sendPasswordReset(
            email: (form.control('email').value as String).trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(context.t('password_reset_email_sent'))));
        context.pop();
      }
    } on Failure catch (e) {
      if (mounted) _showError(context.t(e.messageKey));
    } catch (_) {
      if (mounted) _showError(context.t('unexpected_error'));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('forgot_password')),
        actions: const [LanguageSwitchButton()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ReactiveForm(
            formGroup: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.t('reset_password_instructions'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                ReactiveTextField<String>(
                  formControlName: 'email',
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: context.t('email')),
                  validationMessages: {
                    ValidationMessage.required: (_) => context
                        .t('required')
                        .replaceFirst('{field}', context.t('email')),
                    ValidationMessage.email: (_) => context.t('invalid_email'),
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.t('send_reset_link')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
