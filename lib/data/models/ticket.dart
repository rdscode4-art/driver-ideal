// Ticket model for support tickets
class Ticket {
  final String userId;
  final String userType;
  final String status;
  final String id;
  final String createdAt;
  final String ticketTitle;
  final String description;
  final String priority;
  final int v;  // This is for the __v field from MongoDB

  const Ticket({
    required this.userId,
    required this.userType,
    required this.status,
    required this.id,
    required this.createdAt,
    required this.ticketTitle,
    required this.description,
    required this.priority,
    this.v = 0,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      userId: json['userId'] ?? '',
      userType: json['userType'] ?? 'Driver',
      status: json['status'] ?? 'open',
      id: json['_id'] ?? '',
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
      ticketTitle: json['ticketTitle'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'high',
      v: json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticketTitle': ticketTitle,
      'description': description,
      'priority': priority,
      'userId': userId,
      'userType': userType,
      'status': status,
      '_id': id,
      'createdAt': createdAt,
      '__v': v,
    };
  }
}
