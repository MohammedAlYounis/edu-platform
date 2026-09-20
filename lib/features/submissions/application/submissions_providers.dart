import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/submission.dart';
import '../data/repositories/submissions_repository.dart';

final mySubmissionProvider =
    FutureProvider.autoDispose.family<Submission?, String>((ref, contentId) {
  return ref.watch(submissionsRepositoryProvider).fetchMySubmissionForContent(contentId);
});

final recentSubmissionsProvider = FutureProvider.autoDispose<List<Submission>>((ref) {
  return ref.watch(submissionsRepositoryProvider).fetchMyRecentSubmissions();
});

enum UploadStatus { idle, uploading, success, error }

class UploadState {
  final UploadStatus status;
  final String? errorMessage;
  const UploadState({this.status = UploadStatus.idle, this.errorMessage});
}

/// يدير عملية رفع الحل خطوة بخطوة (بند 50 في التصميم):
/// اختيار ملف → تأكيد → رفع → تحديث الحالة، مع منع الضغط المتكرر.
class SubmissionUploadNotifier extends AutoDisposeFamilyNotifier<UploadState, String> {
  @override
  UploadState build(String contentId) => const UploadState();

  Future<void> upload(File file, String fileName) async {
    if (state.status == UploadStatus.uploading) return; // منع الضغط المتكرر

    state = const UploadState(status: UploadStatus.uploading);
    try {
      await ref.read(submissionsRepositoryProvider).submitSolution(
            contentId: arg,
            file: file,
            fileName: fileName,
          );
      state = const UploadState(status: UploadStatus.success);
      ref.invalidate(mySubmissionProvider(arg));
    } catch (e) {
      state = UploadState(
        status: UploadStatus.error,
        errorMessage: e.toString().contains('لديك حل مُرسَل')
            ? 'لديك حل مُرسَل مسبقًا لهذا الاختبار.'
            : 'تعذر رفع الملف، تحقق من الاتصال وحاول مرة أخرى.',
      );
    }
  }
}

final submissionUploadProvider = NotifierProvider.autoDispose
    .family<SubmissionUploadNotifier, UploadState, String>(SubmissionUploadNotifier.new);
