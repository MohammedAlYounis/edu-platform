import 'dart:math';

/// Creates an ASCII-only object name while preserving the original extension.
///
/// The original file name is stored separately in the database for display.
String createStorageFileName(String originalName) {
  final dotIndex = originalName.lastIndexOf('.');
  final extension = dotIndex >= 0 ? originalName.substring(dotIndex + 1) : '';
  final safeExtension = RegExp(r'^[a-zA-Z0-9]{1,10}$').hasMatch(extension)
      ? '.$extension'
      : '';
  final randomPart = Random.secure().nextInt(0x7fffffff);

  return 'upload_${DateTime.now().microsecondsSinceEpoch}_$randomPart$safeExtension';
}
