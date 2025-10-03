import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool loading = false;
  String msg = "";

  void login() async {
    setState(() {
      loading = true;
      msg = "";
    });

    try {
      final res = await ApiService.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      setState(() => loading = false);

      if (res['success']) {
        final int userId = res['user_id'];
        final bool hasQr = res['has_qr'];
        final bool isAdmin = res['is_admin'] == 1;

        if (isAdmin) {
          // Redirect admin to Admin Dashboard
          Navigator.pushReplacementNamed(context, '/admin_dashboard');
        } else {
          // Redirect normal users
          if (hasQr) {
            Navigator.pushReplacementNamed(
              context,
              '/qr_screen',
              arguments: {"user_id": userId},
            );
          } else {
            Navigator.pushReplacementNamed(
              context,
              '/user_form',
              arguments: {"userId": userId}, // ✅ Pass userId here
            );
          }
        }
      } else {
        setState(() => msg = res['message'] ?? "Login failed");
      }
    } catch (e) {
      setState(() {
        loading = false;
        msg = "Error connecting to server";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: login,
                    child: const Text("Login"),
                  ),
            const SizedBox(height: 20),
            Text(
              msg,
              style: const TextStyle(color: Colors.red),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/register'),
              child: const Text("Register here"),
            ),
            // Forgot password navigation
    TextButton(
      onPressed: () => Navigator.pushReplacementNamed(context, '/forgot_password'),
      child: Text("Forgot Password"),
              
            ),
          ],
        ),
      ),
    );
  }
}
