
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

  // Tìm kiếm và lọc công việc
  final TextEditingController _searchController =
  TextEditingController();

  String _searchKeyword = '';
  String _selectedStatus = 'all';
  String _selectedPriority = 'all';
  String _selectedAssignee = 'all';

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

// Tìm kiếm và lọc công việc
  List<Task> _getFilteredTasks(String type) {
    final tasks = _getTasksByType(type);

    return tasks.where((task) {
      final matchesName = task.title
          .toLowerCase()
          .contains(_searchKeyword.toLowerCase());

      final matchesStatus = _selectedStatus == 'all' ||
          task.status == _selectedStatus;

      final matchesPriority = _selectedPriority == 'all' ||
          task.priority == _selectedPriority;

      final matchesAssignee = _selectedAssignee == 'all' ||
          task.assignedTo == _selectedAssignee;

      return matchesName &&
          matchesStatus &&
          matchesPriority &&
          matchesAssignee;
    }).toList();
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
    final tasks = _getFilteredTasks(type);

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

    return Column(
      children: [
        // Ô tìm kiếm
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo tên công việc...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchKeyword = '';
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchKeyword = value.trim();
              });
            },
          ),
        ),

        // Bộ lọc trạng thái
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Lọc theo trạng thái',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tất cả trạng thái')),
              DropdownMenuItem(value: 'todo', child: Text('Chưa thực hiện')),
              DropdownMenuItem(
                  value: 'in_progress', child: Text('Đang thực hiện')),
              DropdownMenuItem(
                  value: 'completed', child: Text('Đã hoàn thành')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedStatus = value ?? 'all';
              });
            },
          ),
        ),

        const SizedBox(height: 10),

        // Bộ lọc ưu tiên
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedPriority,
            decoration: const InputDecoration(
              labelText: 'Lọc theo mức độ ưu tiên',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tất cả mức ưu tiên')),
              DropdownMenuItem(value: 'low', child: Text('Thấp')),
              DropdownMenuItem(value: 'medium', child: Text('Trung bình')),
              DropdownMenuItem(value: 'high', child: Text('Cao')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedPriority = value ?? 'all';
              });
            },
          ),
        ),

        const SizedBox(height: 10),

        // Bộ lọc người phụ trách
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedAssignee,
            decoration: const InputDecoration(
              labelText: 'Lọc theo người phụ trách',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: 'all',
                child: Text('Tất cả người phụ trách'),
              ),
              ..._tasks
                  .where((task) => task.assignedTo.isNotEmpty)
                  .map((task) => task.assignedTo)
                  .toSet()
                  .map((id) =>
                  DropdownMenuItem(
                    value: id,
                    child: Text(
                      id,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedAssignee = value ?? 'all';
              });
            },
          ),
        ),

        const SizedBox(height: 8),

        // Danh sách kết quả
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadTasks,
            child: tasks.isEmpty
                ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 60),
                Icon(
                  Icons.search_off,
                  size: 55,
                  color: Colors.grey,
                ),
                SizedBox(height: 12),
                Center(
                  child: Text('Không tìm thấy công việc phù hợp'),
                ),
              ],
            )
                : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return _buildTaskCard(tasks[index]);
              },
            ),
          ),
        ),
      ],
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
      _searchController.dispose();
      super.dispose();
    }
}
