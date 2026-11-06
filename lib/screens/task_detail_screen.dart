import 'package:flutter/material.dart';

import '../models/task_model.dart';
import '../services/task_service.dart';
import 'task_form_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final String currentUserId;

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.currentUserId,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TaskService _taskService = TaskService();

  bool _isDeleting = false;
  bool _isUpdatingStatus = false;
  bool _isUpdatingPriority = false;
  bool _isSharing = false;

  late String _selectedStatus;
  late String _selectedPriority;

  @override
  void initState() {
    super.initState();

    const validStatuses = ['todo', 'in_progress', 'completed'];
    const validPriorities = ['low', 'medium', 'high'];

    _selectedStatus = validStatuses.contains(widget.task.status)
        ? widget.task.status
        : 'todo';

    _selectedPriority = validPriorities.contains(widget.task.priority)
        ? widget.task.priority
        : 'medium';
  }

  String _statusText(String status) {
    switch (status) {
      case 'in_progress':
        return 'Đang thực hiện';
      case 'completed':
        return 'Đã hoàn thành';
      default:
        return 'Chưa thực hiện';
    }
  }

  String _priorityText(String priority) {
    switch (priority) {
      case 'low':
        return 'Thấp';
      case 'high':
        return 'Cao';
      default:
        return 'Trung bình';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'low':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  Future<void> _editTask() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TaskFormScreen(
              task: widget.task,
              currentUserId: widget.currentUserId,
            ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: const Text(
              'Bạn có chắc chắn muốn xóa công việc này không?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await _taskService.deleteTask(widget.task.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xóa công việc thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể xóa công việc: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == widget.task.status) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trạng thái chưa thay đổi')),
      );
      return;
    }

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      await _taskService.updateTaskStatus(
        widget.task.id,
        _selectedStatus,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật trạng thái thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUpdatingStatus = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể cập nhật trạng thái: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updatePriority() async {
    if (_selectedPriority == widget.task.priority) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mức độ ưu tiên chưa thay đổi'),
        ),
      );
      return;
    }

    setState(() {
      _isUpdatingPriority = true;
    });

    try {
      await _taskService.updateTask(
        widget.task.id,
        {'priority': _selectedPriority},
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật mức độ ưu tiên thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUpdatingPriority = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể cập nhật mức độ ưu tiên: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chưa thiết lập';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // Chia sẻ công việc cho nhiều người bằng email.
  // Chia sẻ công việc và cấp quyền Viewer hoặc Editor.
  Future<void> _shareTask() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return const _ShareTaskDialog();
      },
    );

    if (!mounted || result == null) return;

    final input = result['emails'] ?? '';
    final permission = result['permission'] ?? 'viewer';

    if (input.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập email người nhận'),
        ),
      );
      return;
    }

    // Tách email theo dấu phẩy, chấm phẩy hoặc xuống dòng.
    final emails = input
        .split(RegExp(r'[,;\n]+'))
        .map((email) => email.trim().toLowerCase())
        .where((email) => email.isNotEmpty)
        .toSet()
        .toList();

    if (emails.isEmpty) return;

    // Kiểm tra định dạng email.
    final emailRegex = RegExp(
      r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$',
    );

    final invalidEmails = emails
        .where((email) => !emailRegex.hasMatch(email))
        .toList();

    if (invalidEmails.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Email không hợp lệ: ${invalidEmails.join(', ')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSharing = true;
    });

    try {
      await _taskService.shareTask(
        taskId: widget.task.id,
        emails: emails,
        permission: permission,
      );

      if (!mounted) return;

      final permissionText =
      permission == 'viewer' ? 'Chỉ xem (Viewer)' : 'Chỉnh sửa (Editor)';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã chia sẻ cho ${emails.length} người với quyền $permissionText!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Chia sẻ thất bại: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  // Hiển thị một dòng thông tin kèm icon
  Widget _buildInfo(String label,
      String value,
      IconData icon, {
        Color color = Colors.blue,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(width: 14),
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value.isEmpty ? 'Chưa có thông tin' : value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF171936),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Nhãn trạng thái và ưu tiên hiện tại
  Widget _buildCurrentValue({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tiêu đề của khu vực chức năng
  Widget _buildSectionHeader(String title,
      IconData icon,
      Color color,) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF171936),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Nút lưu
  Widget _buildSaveButton({
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
          width: 19,
          height: 19,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Icon(Icons.save),
        label: Text(
          isLoading ? 'Đang cập nhật...' : label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // Khu vực cập nhật trạng thái
  Widget _buildStatusSection() {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSectionHeader(
            'Cập nhật trạng thái công việc',
            Icons.sync,
            Colors.blue,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(12),
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.checklist,
                      color: Colors.blue,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'todo',
                      child: Text('Chưa thực hiện'),
                    ),
                    DropdownMenuItem(
                      value: 'in_progress',
                      child: Text('Đang thực hiện'),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Đã hoàn thành'),
                    ),
                  ],
                  onChanged: _isUpdatingStatus
                      ? null
                      : (value) {
                    if (value != null) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),
                _buildSaveButton(
                  label: 'Lưu trạng thái',
                  isLoading: _isUpdatingStatus,
                  onPressed: _updateStatus,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Khu vực cập nhật mức độ ưu tiên
  Widget _buildPrioritySection() {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSectionHeader(
            'Thiết lập mức độ ưu tiên',
            Icons.flag,
            Colors.deepPurple,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedPriority,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(12),
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.flag,
                      color: Colors.red,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'low',
                      child: Text('Thấp'),
                    ),
                    DropdownMenuItem(
                      value: 'medium',
                      child: Text('Trung bình'),
                    ),
                    DropdownMenuItem(
                      value: 'high',
                      child: Text('Cao'),
                    ),
                  ],
                  onChanged: _isUpdatingPriority
                      ? null
                      : (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPriority = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),
                _buildSaveButton(
                  label: 'Lưu mức độ ưu tiên',
                  isLoading: _isUpdatingPriority,
                  onPressed: _updatePriority,
                  color: Colors.deepPurple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        title: const Text(
          'Chi tiết công việc',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Trang chủ',
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ tên và mô tả công việc
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.blue.shade50,
                      child: const Icon(
                        Icons.assignment,
                        color: Colors.blue,
                        size: 35,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF171936),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            task.description.isEmpty
                                ? 'Chưa có mô tả'
                                : task.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Thẻ thông tin công việc
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfo(
                      'Ngày tạo',
                      _formatDate(task.createdAt),
                      Icons.calendar_month,
                    ),
                    _buildInfo(
                      'Ngày bắt đầu',
                      _formatDate(task.startDate),
                      Icons.calendar_today,
                    ),
                    _buildInfo(
                      'Hạn hoàn thành',
                      _formatDate(task.dueDate),
                      Icons.event,
                    ),
                    _buildInfo(
                      'Người tạo',
                      task.createdBy,
                      Icons.person,
                      color: Colors.indigo,
                    ),
                    _buildInfo(
                      'Người được giao',
                      task.assignedTo,
                      Icons.person,
                      color: Colors.indigo,
                    ),
                    _buildCurrentValue(
                      label: 'Mức độ ưu tiên',
                      value: _priorityText(task.priority),
                      color: _priorityColor(task.priority),
                      icon: Icons.flag,
                    ),
                    _buildCurrentValue(
                      label: 'Trạng thái hiện tại',
                      value: _statusText(task.status),
                      color: _statusColor(task.status),
                      icon: Icons.check_circle,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            _buildStatusSection(),

            const SizedBox(height: 16),

            _buildPrioritySection(),

            const SizedBox(height: 20),


            // Khu vực các nút chức năng
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isDeleting ? null : _editTask,
                        icon: const Icon(Icons.edit),
                        label: const Text('Chỉnh sửa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isDeleting ? null : _deleteTask,
                        icon: const Icon(Icons.delete),
                        label: const Text('Xóa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Nút chia sẻ công việc
                OutlinedButton.icon(
                  onPressed: _isSharing ? null : _shareTask,
                  icon: _isSharing
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.share),
                  label: Text(
                    _isSharing
                        ? 'Đang chia sẻ...'
                        : 'Chia sẻ công việc cho nhiều người',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),

            if (_isDeleting) ...[
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
// Hộp thoại nhập email chia sẻ công việc.
// Hộp thoại chia sẻ công việc và chọn quyền truy cập.
class _ShareTaskDialog extends StatefulWidget {
  const _ShareTaskDialog();

  @override
  State<_ShareTaskDialog> createState() =>
      _ShareTaskDialogState();
}

class _ShareTaskDialogState extends State<_ShareTaskDialog> {
  final TextEditingController _emailController =
  TextEditingController();

  String _selectedPermission = 'viewer';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      title: const Row(
        children: [
          Icon(Icons.share, color: Colors.blue),
          SizedBox(width: 10),
          Expanded(
            child: Text('Chia sẻ công việc'),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập email của những người bạn muốn chia sẻ công việc.',
              style: TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _emailController,
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                hintText: 'Ví dụ:\nabc@gmail.com\ndef@gmail.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Có thể nhập nhiều email, cách nhau bằng dấu phẩy, '
                  'dấu chấm phẩy hoặc xuống dòng.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            const Divider(),

            const SizedBox(height: 8),

            const Text(
              'Cấp quyền truy cập',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // Quyền chỉ xem.
            RadioListTile<String>(
              value: 'viewer',
              groupValue: _selectedPermission,
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.blue,
              secondary: const Icon(
                Icons.visibility,
                color: Colors.blue,
              ),
              title: const Text(
                'Viewer - Chỉ xem',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Được xem thông tin công việc, không được chỉnh sửa.',
                style: TextStyle(fontSize: 12),
              ),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPermission = value;
                  });
                }
              },
            ),

            const Divider(height: 8),

            // Quyền chỉnh sửa.
            RadioListTile<String>(
              value: 'editor',
              groupValue: _selectedPermission,
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.deepPurple,
              secondary: const Icon(
                Icons.edit,
                color: Colors.deepPurple,
              ),
              title: const Text(
                'Editor - Chỉnh sửa',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Được xem và chỉnh sửa thông tin công việc.',
                style: TextStyle(fontSize: 12),
              ),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPermission = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Hủy'),
        ),

        ElevatedButton.icon(
          icon: const Icon(Icons.share),
          onPressed: () {
            Navigator.pop(
              context,
              {
                'emails': _emailController.text,
                'permission': _selectedPermission,
              },
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          label: const Text('Chia sẻ'),
        ),
      ],
    );
  }
}
