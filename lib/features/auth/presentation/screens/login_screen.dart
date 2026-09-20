import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/localization/localization_extension.dart';
import '../../../../shared/widgets/language_switch_button.dart';
import '../../../../core/routing/app_router.dart';
import '../../application/auth_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final form = FormGroup({
    'email': FormControl<String>(
      validators: [Validators.required, Validators.email],
    ),
    'password': FormControl<String>(
      validators: [Validators.required, Validators.minLength(6)],
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
      await ref.read(authNotifierProvider.notifier).signIn(
            email: form.control('email').value as String,
            password: form.control('password').value as String,
          );
      // التوجيه لـ /home يحدث تلقائيًا عبر GoRouter redirect بعد نجاح تسجيل الدخول
    } on Failure catch (e) {
      if (mounted) _showError(context.t(e.messageKey));
    } catch (_) {
      if (mounted) _showError(context.t('unexpected_error'));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _continueWithGoogle() async {
    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    } on Failure catch (e) {
      if (mounted) _showError(context.t(e.messageKey));
    }
  }

  Future<void> _resendConfirmation() async {
    final email = form.control('email').value as String?;
    if (email == null || email.trim().isEmpty) {
      _showError(context.t('enter_email'));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .resendConfirmationEmail(email: email.trim());
      if (mounted) _showSuccess(context.t('confirmation_sent'));
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: const [LanguageSwitchButton()]),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ReactiveForm(
              formGroup: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images/app-icon-edu.jpeg',
                    width: 72,
                    height: 72,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    context.t('login'),
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
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
                      ValidationMessage.email: (_) =>
                          context.t('invalid_email'),
                    },
                  ),
                  const SizedBox(height: 16),
                  ReactiveTextField<String>(
                    formControlName: 'password',
                    obscureText: true,
                    decoration:
                        InputDecoration(labelText: context.t('password')),
                    validationMessages: {
                      ValidationMessage.required: (_) => context
                          .t('required')
                          .replaceFirst('{field}', context.t('password')),
                      ValidationMessage.minLength: (_) =>
                          context.t('password_min_length'),
                    },
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => context.push(AppRoutes.forgotPassword),
                          child: Text(context.t('forgot_password')),
                        ),
                        TextButton(
                          onPressed: _isSubmitting ? null : _resendConfirmation,
                          child: Text(context.t('resend_confirmation')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.t('login')),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _continueWithGoogle,
                    icon: const Icon(Icons.g_mobiledata),
                    label: Text(context.t('continue_with_google')),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => context.push(AppRoutes.register),
                    child: Text(context.t('no_account')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
