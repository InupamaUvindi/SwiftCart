class NotificationModel {
  final String userId;
  final String title;
  final String body;
  final bool isRead;
  final String type;
  final DateTime createdAt;

  NotificationModel({
    required this.userId,
    required this.title,
    required this.body,
    this.isRead = false,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'isRead': isRead,
      'type': type,
      'createdAt': createdAt,
    };
  }
}