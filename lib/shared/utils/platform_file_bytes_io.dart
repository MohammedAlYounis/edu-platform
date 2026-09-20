import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<Uint8List?> readPlatformFileBytesImpl(PlatformFile file) async {
  if (file.bytes != null) return file.bytes;
  final path = file.path;
  return path == null ? null : File(path).readAsBytes();
}
