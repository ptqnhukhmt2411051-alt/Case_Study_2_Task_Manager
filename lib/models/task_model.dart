class Task {
  final String id;
  final String title;
  final String description;
  final String createdBy;
  final String assignedTo;
  final String status;
  final String priority;
  final DateTime startDate;
  final DateTime dueDate;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.assignedTo,
    required this.status,
    required this.priority,
    required this.startDate,
    required this.dueDate,
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['_id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      createdBy: json['createdBy']?.toString() ?? '',
      assignedTo: json['assignedTo']?.toString() ?? '',
      status: json['status'] ?? 'todo',
      priority: json['priority'] ?? 'medium',
      startDate: DateTime.tryParse(
        json['startDate']?.toString() ?? '',
      ) ??
          DateTime.now(),
      dueDate: DateTime.tryParse(
        json['dueDate']?.toString() ?? '',
      ) ??
          DateTime.now(),
      createdAt: DateTime.tryParse(
        json['createdAt']?.toString() ?? '',
      ) ??
          DateTime.now(),
    );
  }
}