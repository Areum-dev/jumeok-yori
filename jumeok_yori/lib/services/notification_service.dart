// 추후 FCM/이메일 알림 연동 예정 (현재는 placeholder)
class NotificationService {
  // TODO: FCM 푸시 알림 연동
  static Future<void> sendApprovalNotification({
    required String userId,
    required String message,
  }) async {
    // placeholder - 추후 구현
  }

  // TODO: 이메일 알림 연동
  static Future<void> sendEmailNotification({
    required String email,
    required String subject,
    required String body,
  }) async {
    // placeholder - 추후 구현
  }
}
