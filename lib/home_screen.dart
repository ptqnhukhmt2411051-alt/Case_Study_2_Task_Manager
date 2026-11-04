
import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> handleLogout(BuildContext context) async {
    await AuthService().logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.task_alt,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Ch├áo mß╗½ng ─æß║┐n vß╗¢i Task Manager!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.person),
              label: const Text('Th├┤ng tin c├í nh├ón'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => handleLogout(context),
              icon: const Icon(Icons.logout),
              label: const Text('─É─âng xuß║Ñt'),
            ),
          ],
        ),
      ),
    );
  }
}
