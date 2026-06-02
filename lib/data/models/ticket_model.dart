
class Ticket {
  final String userId;
  final String userType;
  final String status;
  final String id;
  final String createdAt;
  final String ticketTitle;
  final String description;
  final String priority;

  Ticket({
    required this.userId,
    required this.userType,
    required this.status,
    required this.id,
    required this.createdAt,
    this.ticketTitle = '',
    this.description = '',
    this.priority = 'high',
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      userId: json['userId'] ?? '',
      userType: json['userType'] ?? '',
      status: json['status'] ?? '',
      id: json['_id'] ?? '',
      createdAt: json['createdAt'] ?? '',
      ticketTitle: json['ticketTitle'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'high',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userType': userType,
      'status': status,
      '_id': id,
      'createdAt': createdAt,
      'ticketTitle': ticketTitle,
      'description': description,
      'priority': priority,
    };
  }
}