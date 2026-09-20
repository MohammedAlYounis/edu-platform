import 'package:edu_platform/core/errors/failure.dart';
import 'package:edu_platform/core/network/supabase_client_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('mapExceptionToFailure', () {
    test('maps invalid login to message key', () {
      final failure = mapExceptionToFailure(
        const AuthException('Invalid login credentials'),
      );
      expect(failure, isA<AuthFailure>());
      expect(failure.messageKey, 'invalid_credentials');
    });

    test('maps duplicate student number pattern', () {
      const failure = ValidationFailure('student_number_taken');
      expect(failure.messageKey, 'student_number_taken');
    });
  });
}
