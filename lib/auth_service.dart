
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Android Emulator dung 10.0.2.2 de truy cap may tinh.
// Neu chay tren Windows desktop, doi thanh localhost.
const String baseUrl = 'http://10.0.2.2:3000';

class AuthService {
  // Dang ky tai khoan
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201) {
      return data;
    }

    throw Exception(data['message'] ?? 'Dang ky that bai');
  }

  // Dang nhap va luu token
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      final token = data['token'];

      if (token is String && token.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
      }

      return data;
    }

    throw Exception(data['message'] ?? 'Dang nhap that bai');
  }

  // Dang xuat: xoa token da luu
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // Lay token hien tai neu co
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Lay thong tin nguoi dung hien tai
  Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Vui lòng đăng nhập lại');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data =
    jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data['message'] ?? 'Không thể lấy thông tin cá nhân',
    );
  }

  // Cap nhat thong tin ca nhan
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Vui lòng đăng nhập lại');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
      }),
    );

    final data =
    jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data['message'] ?? 'Cập nhật thông tin thất bại',
    );
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Vui lòng đăng nhập lại');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/api/auth/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    final data =
    jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data['message'] ?? 'Đổi mật khẩu thất bại',
    );
  }
}


