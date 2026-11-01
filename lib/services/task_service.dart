import '../models/task_model.dart';

class TaskService {
  Future<List<Task>> getTasks(String type) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final now = DateTime.now();

    final tasks = [
      Task(
        id: '1',
        title: 'Hoàn thành báo cáo nhóm',
        description: 'Thực hiện báo cáo môn học và hoàn thành nội dung.',
        createdBy: 'Nguyễn Văn A',
        assignedTo: 'Phạm Thị Như',
        status: 'in_progress',
        priority: 'high',
        startDate: now,
        dueDate: now.add(const Duration(days: 5)),
        createdAt: now,
      ),
      Task(
        id: '2',
        title: 'Chuẩn bị bài thuyết trình',
        description: 'Chuẩn bị nội dung và slide thuyết trình.',
        createdBy: 'Trần Văn B',
        assignedTo: 'Phạm Thị Như',
        status: 'completed',
        priority: 'medium',
        startDate: now,
        dueDate: now.add(const Duration(days: 7)),
        createdAt: now,
      ),
      Task(
        id: '3',
        title: 'Thiết kế giao diện ứng dụng',
        description: 'Thiết kế màn hình quản lý công việc.',
        createdBy: 'Phạm Thị Như',
        assignedTo: 'Phạm Thị Như',
        status: 'todo',
        priority: 'low',
        startDate: now,
        dueDate: now.add(const Duration(days: 10)),
        createdAt: now,
      ),
    ];

    switch (type) {
      case 'created':
        return tasks.where((t) => t.id == '3').toList();

      case 'assigned':
        return tasks.where((t) => t.id == '1').toList();

      case 'accepted':
        return tasks.where((t) => t.id == '2').toList();

      case 'shared':
        return tasks.where((t) => t.id == '1' || t.id == '2').toList();

      default:
        return [];
    }
  }
}