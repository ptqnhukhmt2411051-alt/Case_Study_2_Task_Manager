import 'package:flutter/material.dart';
import '../models/task_model.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task task;

  const TaskDetailScreen({
    super.key,
    required this.task,
  });

  String statusText(String status) {
    switch (status) {
      case 'in_progress':
        return 'Đang thực hiện';
      case 'completed':
        return 'Đã hoàn thành';
      default:
        return 'Chưa thực hiện';
    }
  }

  String priorityText(String priority) {
    switch (priority) {
      case 'high':
        return 'Cao';
      case 'medium':
        return 'Trung bình';
      default:
        return 'Thấp';
    }
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Widget infoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Mô tả công việc',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(task.description),
            const Divider(height: 32),
            infoItem('Người tạo', task.createdBy, Icons.person),
            infoItem('Người phụ trách', task.assignedTo, Icons.assignment_ind),
            infoItem('Trạng thái', statusText(task.status), Icons.flag),
            infoItem('Mức độ ưu tiên', priorityText(task.priority), Icons.star),
            infoItem('Ngày bắt đầu', formatDate(task.startDate), Icons.calendar_today),
            infoItem('Hạn hoàn thành', formatDate(task.dueDate), Icons.event),
            infoItem('Ngày tạo', formatDate(task.createdAt), Icons.access_time),
          ],
        ),
      ),
    );
  }
}