import 'package:freezed_annotation/freezed_annotation.dart';

part 'subject.freezed.dart';

@Freezed(fromJson: false, toJson: false)
class Subject with _$Subject {
  const factory Subject({
    required String id,
    required String title,
    String? description,
    String? imageUrl,
    required bool isActive,
    required int orderIndex,
    // تُملأ من استعلام منفصل (count) وليست عمودًا في الجدول — بند 8 في التصميم
    @Default(0) int lessonsCount,
    @Default(0) int examsCount,
  }) = _Subject;

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        imageUrl: json['image_url'] as String?,
        isActive: json['is_active'] as bool,
        orderIndex: json['order_index'] as int,
      );
}
