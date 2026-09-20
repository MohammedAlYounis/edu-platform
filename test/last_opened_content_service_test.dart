import 'package:edu_platform/core/constants/app_enums.dart';
import 'package:edu_platform/shared/services/last_opened_content_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LastOpenedContentService', () {
    late SharedPreferences prefs;
    late LastOpenedContentService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = LastOpenedContentService(prefs);
    });

    test('stores and deduplicates by content id', () async {
      await service.recordOpen(
        contentId: 'a',
        title: 'Lesson A',
        type: ContentType.lesson,
      );
      await service.recordOpen(
        contentId: 'b',
        title: 'Exam B',
        type: ContentType.exam,
      );
      await service.recordOpen(
        contentId: 'a',
        title: 'Lesson A updated',
        type: ContentType.lesson,
      );

      final entries = service.readEntries();
      expect(entries.length, 2);
      expect(entries.first.id, 'a');
      expect(entries.first.title, 'Lesson A updated');
    });
  });
}
