
import 'package:flutter/material.dart';

import '../auth_service.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import 'task_detail_screen.dart';
import 'task_form_screen.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();

  final List<String> _types = [
    'created',
    'assigned',
    'accepted',
    'shared',
  ];

  final List<String> _titles = [
    'Đã tạo',
    'Được giao',
    'Đã nhận',
    'Được chia sẻ',
  ];

  String _currentUserId = '';

  bool _isLoadingUser = true;
  bool _isLoadingTasks = false;

  String? _errorMessage;

  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: _types.length,
      vsync: this,
    );

    _initializeScreen();
  }

  // Khởi tạo màn hình
  Future<void> _initializeScreen() async {
    await _loadCurrentUser();
    await _loadTasks();
  }

  // Lấy ID người dùng đang đăng nhập
  Future<void> _loadCurrentUser() async {
    try {
      final userId = await _authService.getCurrentUserId();

      if (!mounted) return;

      setState(() {
        _currentUserId = userId;
        _isLoadingUser = false;
      });

      debugPrint('ID người dùng: $_currentUserId');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _currentUserId = '';
        _isLoadingUser = false;
        _errorMessage = 'Không thể lấy thông tin tài khoản: $e';
      });

      debugPrint('Lỗi lấy ID người dùng: $e');
    }
  }

  // Tải danh sách công việc từ API
  Future<void> _loadTasks() async {
    if (!mounted) return;

    setState(() {
      _isLoadingTasks = true;
      _errorMessage = null;
    });

    try {
      final tasks = await _taskService.getTasks('all');

      if (!mounted) return;

      setState(() {
        _tasks = tasks;
        _isLoadingTasks = false;
      });

      debugPrint('Tổng số công việc: ${_tasks.length}');
      debugPrint('ID người dùng: $_currentUserId');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingTasks = false;
        _errorMessage = 'Không thể tải công việc: $e';
      });

      debugPrint('Lỗi tải công việc: $e');
    }
  }

  // Lọc công việc theo từng danh sách
  List<Task> _getTasksByType(String type) {
    switch (type) {
      case 'created':
        return _tasks
            .where((task) => task.createdBy.isNotEmpty)
            .toList();

      case 'assigned':
        return _tasks
            .where((task) => task.assignedTo.isNotEmpty)
            .toList();

      case 'accepted':
        return _tasks
            .where((task) => task.acceptedBy.isNotEmpty)
            .toList();

      case 'shared':
        return _tasks
            .where((task) => task.sharedWith.isNotEmpty)
            .toList();

      default:
        return _tasks;
    }
  }

  // Mở màn hình thêm công việc
  Future<void> _openAddTaskScreen() async {
    if (_currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không lấy được thông tin tài khoản. Vui lòng đăng nhập lại.',
          ),
        ),
      );
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(
          currentUserId: _currentUserId,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _loadTasks();
    }
  }

  // Mở màn hình chi tiết công việc
  Future<void> _openTaskDetail(Task task) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(
          task: task,
          currentUserId: _currentUserId,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _loadTasks();
    }
  }

  // Màu trạng thái
  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  // Tên trạng thái
  String _statusText(String status) {
    switch (status) {
      case 'completed':
        return 'Hoàn thành';
      case 'in_progress':
        return 'Đang thực hiện';
      default:
        return 'Chưa thực hiện';
    }
  }

  // Màu độ ưu tiên
  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'low':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  // Tên độ ưu tiên
  String _priorityText(String priority) {
    switch (priority) {
      case 'high':
        return 'Cao';
      case 'low':
        return 'Thấp';
      default:
        return 'Trung bình';
    }
  }

  // Định dạng ngày
  String _formatDate(DateTime? date) {
    if (date == null) return 'Chưa có';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // Giao diện thẻ công việc
  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openTaskDetail(task),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Chip(
                    label: Text(_statusText(task.status)),
                    backgroundColor:
                    _statusColor(task.status).withValues(alpha: 0.12),
                  ),
                  Chip(
                    label: Text(
                      'Ưu tiên: ${_priorityText(task.priority)}',
                    ),
                    backgroundColor:
                    _priorityColor(task.priority).withValues(alpha: 0.12),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text('Hạn: ${_formatDate(task.dueDate)}'),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Giao diện danh sách công việc
  Widget _buildTaskList(String type) {
    final tasks = _getTasksByType(type);

    if (_isLoadingTasks) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadTasks,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (tasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadTasks,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 130),
            const Icon(
              Icons.assignment_outlined,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Chưa có công việc ${_titles[_types.indexOf(type)]}',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return _buildTaskCard(tasks[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý công việc'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _isLoadingTasks ? null : _loadTasks,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Thêm công việc',
            onPressed: _isLoadingUser ? null : _openAddTaskScreen,
            icon: const Icon(Icons.add),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _titles.map((title) {
            return Tab(text: title);
          }).toList(),
        ),
      ),
      body: _isLoadingUser
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : TabBarView(
        controller: _tabController,
        children: _types.map(_buildTaskList).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
