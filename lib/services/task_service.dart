
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';

class TaskService {
  static const String baseUrl = 'http://10.0.2.2:3000';

  // Lấy danh sách công việc
  Future<List<Task>> getTasks(String type) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/tasks'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Không thể tải danh sách công việc: ${response.statusCode}',
        );
      }


      final dynamic decodedData = jsonDecode(response.body);

      if (decodedData is! List) {
        throw Exception('Dữ liệu danh sách công việc không hợp lệ');
      }

      final tasks = decodedData
          .map<Task>(
            (json) => Task.fromJson(
          Map<String, dynamic>.from(json),
        ),
      )
          .toList();

      switch (type) {
      // Giữ cách hiển thị cũ
        case 'created':
          return tasks
              .where((task) => task.createdBy.isNotEmpty)
              .toList();

        case 'assigned':
          return tasks
              .where((task) => task.assignedTo.isNotEmpty)
              .toList();

      // Công việc đã được nhận
        case 'accepted':
          return tasks
              .where((task) => task.acceptedBy.isNotEmpty)
              .toList();

      // Công việc đã được chia sẻ
        case 'shared':
          return tasks
              .where((task) => task.sharedWith.isNotEmpty)
              .toList();

        default:
          return tasks;
      }
    } catch (e) {
      throw Exception('Lỗi tải danh sách công việc: $e');
    }
  }

  // Thêm công việc mới
  Future<Task> createTask(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/tasks'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      final dynamic responseData = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (responseData is Map && responseData['task'] is Map) {
          return Task.fromJson(
            Map<String, dynamic>.from(responseData['task']),
          );
        }

        throw Exception('Backend không trả về thông tin công việc');
      }

      throw Exception(
        responseData is Map
            ? responseData['message'] ?? 'Không thể thêm công việc'
            : 'Không thể thêm công việc',
      );
    } catch (e) {
      throw Exception('Lỗi thêm công việc: $e');
    }
  }

  // Cập nhật công việc
  Future<Task> updateTask(
      String taskId,
      Map<String, dynamic> data,
      ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/tasks/$taskId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      final dynamic responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData is Map && responseData['task'] is Map) {
          return Task.fromJson(
            Map<String, dynamic>.from(responseData['task']),
          );
        }

        throw Exception('Backend không trả về thông tin công việc');
      }

      throw Exception(
        responseData is Map
            ? responseData['message'] ?? 'Không thể cập nhật công việc'
            : 'Không thể cập nhật công việc',
      );
    } catch (e) {
      throw Exception('Lỗi cập nhật công việc: $e');
    }
  }
  // Xóa công việc
  Future<void> deleteTask(String taskId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/tasks/$taskId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Không thể xóa công việc: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Lỗi xóa công việc: $e');
    }
  }
}
