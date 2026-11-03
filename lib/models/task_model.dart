
class Task {
  final String id;
  final String title;
  final String description;
  final String createdBy;
  final String assignedTo;
  final List<String> acceptedBy;
  final List<String> sharedWith;
  final String status;
  final String priority;
  final DateTime? startDate;
  final DateTime? dueDate;
  final DateTime? createdAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.assignedTo,
    this.acceptedBy = const [],
    this.sharedWith = const [],
    required this.status,
    required this.priority,
    this.startDate,
    this.dueDate,
    this.createdAt,
  });

  // Lấy ID dù dữ liệu là chuỗi hay đối tượng đã populate
  static String _getId(dynamic value) {
    if (value == null) return '';

    if (value is Map) {
      return (value['_id'] ?? value['id'] ?? '').toString();
    }

    return value.toString();
  }

  static List<String> _getIdList(dynamic value) {
    if (value is! List) return [];

    return value
        .map((item) => _getId(item))
        .where((id) => id.isNotEmpty)
        .toList();
  }

  static DateTime? _getDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    return DateTime.tryParse(value.toString());
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: _getId(json['_id'] ?? json['id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      createdBy: _getId(json['createdBy']),
      assignedTo: _getId(json['assignedTo']),
      acceptedBy: _getIdList(json['acceptedBy']),
      sharedWith: _getIdList(json['sharedWith']),
      status: json['status']?.toString() ?? 'todo',
      priority: json['priority']?.toString() ?? 'medium',
      startDate: _getDate(json['startDate']),
      dueDate: _getDate(json['dueDate']),
      createdAt: _getDate(json['createdAt']),
    );
  }
  String get statusText {
    switch (status) {
      case 'todo':
        return 'Chưa thực hiện';
      case 'in_progress':
        return 'Đang thực hiện';
      case 'completed':
        return 'Đã hoàn thành';
      default:
        return 'Chưa thực hiện';
    }
  }
}
