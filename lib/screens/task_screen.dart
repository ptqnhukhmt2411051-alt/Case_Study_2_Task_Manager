import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import 'task_detail_screen.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TaskService _taskService = TaskService();

  late final List<Future<List<Task>>> _taskFutures;

  final List<String> types = [
    'created',
    'assigned',
    'accepted',
    'shared',
  ];

  final List<String> titles = [
    'Đã tạo',
    'Được giao',
    'Đã nhận',
    'Được chia sẻ',
  ];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);

    _taskFutures = types
        .map((type) => _taskService.getTasks(type))
        .toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

  Color statusColor(String status) {
    switch (status) {
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String priorityText(String priority) {
    switch (priority) {
      case 'high':
        return 'Ưu tiên cao';
      case 'medium':
        return 'Ưu tiên trung bình';
      default:
        return 'Ưu tiên thấp';
    }
  }

  Color priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Widget buildTaskList(String type) {
    return FutureBuilder<List<Task>>(
      future: _taskFutures[types.indexOf(type)],
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Không thể tải công việc.'));
        }

        final tasks = snapshot.data ?? [];

        if (tasks.isEmpty) {
          return const Center(
            child: Text('Chưa có công việc nào.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskDetailScreen(task: task),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Người phụ trách: ${task.assignedTo}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text(statusText(task.status)),
                            backgroundColor:
                            statusColor(task.status).withValues(alpha: 12),
                            labelStyle: TextStyle(
                              color: statusColor(task.status),
                            ),
                            side: BorderSide.none,
                          ),
                          Chip(
                            label: Text(priorityText(task.priority)),
                            backgroundColor:
                            priorityColor(task.priority).withValues(alpha: 12),
                            labelStyle: TextStyle(
                              color: priorityColor(task.priority),
                            ),
                            side: BorderSide.none,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Hạn hoàn thành: ${formatDate(task.dueDate)}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản lý công việc',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: titles.map((title) => Tab(text: title)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: types.map((type) => buildTaskList(type)).toList(),
      ),
    );
  }
}