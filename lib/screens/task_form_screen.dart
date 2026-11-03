
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;
  final String currentUserId;

  const TaskFormScreen({
    super.key,
    this.task,
    required this.currentUserId,
  });

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _assignedToController = TextEditingController();

  final TaskService _taskService = TaskService();

  String _status = 'todo';
  String _priority = 'medium';

  DateTime? _startDate;
  DateTime? _dueDate;

  bool _isSaving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();

    final task = widget.task;

    if (task != null) {
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _assignedToController.text = task.assignedTo;

      _status = task.status;
      _priority = task.priority;
      _startDate = task.startDate;
      _dueDate = task.dueDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assignedToController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isStartDate) async {
    final initialDate = isStartDate
        ? (_startDate ?? DateTime.now())
        : (_dueDate ?? _startDate ?? DateTime.now());

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    setState(() {
      if (isStartDate) {
        _startDate = pickedDate;

        if (_dueDate != null &&
            _dueDate!.isBefore(pickedDate)) {
          _dueDate = null;
        }
      } else {
        _dueDate = pickedDate;
      }
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chưa chọn ngày';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dueDate != null &&
        _startDate != null &&
        _dueDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hạn hoàn thành phải sau ngày bắt đầu'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'createdBy': widget.task?.createdBy ?? widget.currentUserId,
        'assignedTo': _assignedToController.text.trim().isEmpty
            ? null
            : _assignedToController.text.trim(),
        'status': _status,
        'priority': _priority,
        'startDate': _startDate?.toIso8601String(),
        'dueDate': _dueDate?.toIso8601String(),
      };

      if (_isEditing) {
        await _taskService.updateTask(widget.task!.id, data);
      } else {
        await _taskService.createTask(data);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Cập nhật công việc thành công'
                : 'Thêm công việc thành công',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi lưu công việc: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Chỉnh sửa công việc' : 'Thêm công việc',
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Phần nội dung có thể cuộn
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tên công việc',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Nhập tên công việc',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.task),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Vui lòng nhập tên công việc';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Mô tả',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Nhập mô tả công việc',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'ID người được giao',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _assignedToController,
                      decoration: const InputDecoration(
                        hintText:
                        'Nhập MongoDB User ID (có thể để trống)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Trạng thái',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
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
                          child: Text('Hoàn thành'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _status = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Mức độ ưu tiên',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      initialValue: _priority,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
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
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _priority = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Ngày bắt đầu',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(_formatDate(_startDate)),
                      trailing: TextButton(
                        onPressed: () => _selectDate(true),
                        child: const Text('Chọn ngày'),
                      ),
                    ),

                    const Divider(),

                    const Text(
                      'Hạn hoàn thành',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event),
                      title: Text(_formatDate(_dueDate)),
                      trailing: TextButton(
                        onPressed: () => _selectDate(false),
                        child: const Text('Chọn ngày'),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Nút lưu luôn hiển thị phía dưới
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveTask,
                    icon: _isSaving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.save),
                    label: Text(
                      _isSaving
                          ? 'Đang lưu...'
                          : 'Lưu công việc',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
