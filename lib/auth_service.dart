
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Android Emulator truy cap backend tren may tinh
// Neu chay Windows Desktop, doi thanh http://localhost:3000
const String baseUrl = 'http://10.0.2.2:3000';

class AuthService {
  // ==============================
  // DANG KY TAI KHOAN
  // ==============================
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    final data =
    jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201) {
      return data;
    }

    throw Exception(data['message'] ?? 'Đăng ký thất bại');
  }

  // ==============================
  // DANG NHAP VA LUU TOKEN
  // ==============================
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data =
    jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      final token = data['token'];

      if (token is String && token.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
      }

      return data;
    }

    throw Exception(data['message'] ?? 'Đăng nhập thất bại');
  }

  // ==============================
  // DANG XUAT
  // ==============================
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // ==============================
  // LAY TOKEN HIEN TAI
  // ==============================
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ==============================
  // LAY THONG TIN NGUOI DUNG
  // ==============================
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

  // ==============================
  // LAY ID NGUOI DUNG HIEN TAI
  // ==============================
  Future<String> getCurrentUserId() async {
    final profile = await getProfile();

    final dynamic userData = profile['user'] ?? profile;

    if (userData is! Map) {
      throw Exception('Dữ liệu người dùng không hợp lệ');
    }

    final id = userData['_id'] ?? userData['id'];

    if (id == null || id.toString().isEmpty) {
      throw Exception('Không tìm thấy ID người dùng');
    }

    return id.toString();
  }

  // ==============================
  // CAP NHAT THONG TIN CA NHAN
  // ==============================
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

  // ==============================
  // DOI MAT KHAU
  // ==============================
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
