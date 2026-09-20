/// كل خطأ في التطبيق يُحوَّل إلى Failure قبل أن يصل إلى الـ UI، بحيث لا
/// تظهر رسائل تقنية (PostgrestException، SocketException...) للمستخدم.
///
/// Failure يحمل *مفتاح ترجمة* (messageKey) وليس نصًا جاهزًا — طبقة الـ
/// Repository/Network ليس لديها وصول لـ BuildContext لتترجم، فالترجمة
/// الفعلية تصير بالشاشة نفسها: `context.t(failure.messageKey)`.
sealed class Failure {
  final String messageKey; // مفتاح بملفات assets/lang/*.json
  final String? debugDetails; // للـ logging فقط، لا يُعرض أبدًا للمستخدم

  const Failure(this.messageKey, {this.debugDetails});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.debugDetails}) : super('network_error');
}

class AuthFailure extends Failure {
  const AuthFailure(super.messageKey, {super.debugDetails});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.messageKey, {super.debugDetails});
}

class PermissionFailure extends Failure {
  const PermissionFailure({super.debugDetails}) : super('permission_denied');
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({super.debugDetails}) : super('not_found');
}

class StorageFailure extends Failure {
  const StorageFailure(super.messageKey, {super.debugDetails});
}

class UnknownFailure extends Failure {
  const UnknownFailure({super.debugDetails}) : super('unexpected_error');
}
