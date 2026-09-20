import 'dart:io';

Future<void> main() async {
  final source = File('build/web/assets/.env');
  final destination = File('build/web/.env');

  if (!source.existsSync()) {
    stderr.writeln(
      'Missing build/web/assets/.env. Run "flutter build web" before deploying.',
    );
    exitCode = 1;
    return;
  }

  await destination.writeAsBytes(await source.readAsBytes());
  stdout.writeln('Prepared build/web/.env for Flutter Web deployment.');
}
