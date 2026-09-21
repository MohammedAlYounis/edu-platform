import 'package:edu_platform/shared/utils/storage_file_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates an ASCII storage name and preserves a safe extension', () {
    final storageName = createStorageFileName('كشف حساب محمد.pdf');

    expect(storageName, matches(RegExp(r'^upload_[0-9]+_[0-9]+\.pdf$')));
    expect(storageName.codeUnits.every((codeUnit) => codeUnit < 128), isTrue);
  });

  test('drops unsupported or non-ASCII extensions', () {
    final storageName = createStorageFileName('درس.بي دي اف');

    expect(storageName, matches(RegExp(r'^upload_[0-9]+_[0-9]+$')));
  });
}
