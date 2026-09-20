import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/localization/localization_extension.dart';
import '../../../../shared/widgets/language_switch_button.dart';
import '../../application/auth_notifier.dart';

/// تحقق مخصص: password و confirm_password يجب أن يتطابقا.
/// يُطبَّق على مستوى الـ FormGroup لأنه يقارن حقلين، وليس على حقل واحد.
ValidatorFunction _passwordsMatchValidator() {
  return (AbstractControl<dynamic> control) {
    final form = control as FormGroup;
    final password = form.control('password').value as String?;
    final confirm = form.control('confirmPassword').value as String?;
    if (password != confirm) {
      form.control('confirmPassword').setErrors({'mismatch': true});
      return {'passwordsMismatch': true};
    }
    form.control('confirmPassword').removeError('mismatch');
    return null;
  };
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  late final form = FormGroup({
    'fullName': FormControl<String>(validators: [Validators.required]),
    'studentNumber': FormControl<String>(validators: [Validators.required]),
    'email': FormControl<String>(
        validators: [Validators.required, Validators.email]),
    'password': FormControl<String>(
      validators: [Validators.required, Validators.minLength(6)],
    ),
    'confirmPassword': FormControl<String>(validators: [Validators.required]),
  }, validators: [
    Validators.delegate(_passwordsMatchValidator())
  ]);

  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (form.invalid) {
      form.markAllAsTouched();
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final notifier = ref.read(authNotifierProvider.notifier);
      await notifier.signUp(
        email: form.control('email').value as String,
        password: form.control('password').value as String,
        fullName: form.control('fullName').value as String,
        studentNumber: form.control('studentNumber').value as String,
      );
      if (mounted && !notifier.hasSession) {
        _showError(
          context.t('email_confirmation_required'),
          isError: false,
        );
      }
      // التوجيه لـ /home يحدث تلقائيًا عبر GoRouter بعد نجاح إنشاء الحساب
    } on Failure catch (e) {
      if (mounted) _showError(context.t(e.messageKey));
    } catch (_) {
      if (mounted) _showError(context.t('unexpected_error'));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: isError ? null : Colors.green,
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('create_account')),
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
                ReactiveTextField<String>(
                  formControlName: 'fullName',
                  decoration:
                      InputDecoration(labelText: context.t('full_name')),
                  validationMessages: {
                    ValidationMessage.required: (_) => context
                        .t('required')
                        .replaceFirst('{field}', context.t('full_name')),
                  },
                ),
                const SizedBox(height: 16),
                ReactiveTextField<String>(
                  formControlName: 'studentNumber',
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(labelText: context.t('student_number')),
                  validationMessages: {
                    ValidationMessage.required: (_) => context
                        .t('required')
                        .replaceFirst('{field}', context.t('student_number')),
                  },
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                ReactiveTextField<String>(
                  formControlName: 'password',
                  obscureText: true,
                  decoration: InputDecoration(labelText: context.t('password')),
                  validationMessages: {
                    ValidationMessage.required: (_) => context
                        .t('required')
                        .replaceFirst('{field}', context.t('password')),
                    ValidationMessage.minLength: (_) =>
                        context.t('password_min_length'),
                  },
                ),
                const SizedBox(height: 16),
                ReactiveTextField<String>(
                  formControlName: 'confirmPassword',
                  obscureText: true,
                  decoration:
                      InputDecoration(labelText: context.t('confirm_password')),
                  validationMessages: {
                    ValidationMessage.required: (_) => context
                        .t('required')
                        .replaceFirst('{field}', context.t('confirm_password')),
                    'mismatch': (_) => context.t('passwords_mismatch'),
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
                      : Text(context.t('register')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
