import 'package:edu_platform/core/constants/app_enums.dart';
import 'package:edu_platform/shared/models/content.dart';
import 'package:flutter_test/flutter_test.dart';

Content _exam({
  DateTime? from,
  DateTime? until,
}) {
  return Content(
    id: 'id',
    subjectId: 'sub',
    title: 'Exam',
    type: ContentType.exam,
    filePath: 'path',
    fileName: 'exam.pdf',
    orderIndex: 0,
    availableFrom: from,
    availableUntil: until,
    isActive: true,
  );
}

void main() {
  group('Exam availability boundaries', () {
    test('upcoming before available_from', () {
      final from = DateTime.now().add(const Duration(hours: 2));
      final until = from.add(const Duration(days: 1));
      final exam = _exam(from: from, until: until);
      expect(exam.availability, ExamAvailability.upcoming);
      expect(exam.canAcceptSubmission, isFalse);
    });

    test('active between from and until', () {
      final from = DateTime.now().subtract(const Duration(hours: 1));
      final until = DateTime.now().add(const Duration(hours: 1));
      final exam = _exam(from: from, until: until);
      expect(exam.availability, ExamAvailability.active);
      expect(exam.canAcceptSubmission, isTrue);
    });

    test('expired after available_until', () {
      final until = DateTime.now().subtract(const Duration(minutes: 1));
      final from = until.subtract(const Duration(days: 1));
      final exam = _exam(from: from, until: until);
      expect(exam.availability, ExamAvailability.expired);
      expect(exam.canAcceptSubmission, isFalse);
    });
  });
}
