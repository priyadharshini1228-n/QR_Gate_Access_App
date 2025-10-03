import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _adminKeyController = TextEditingController();

  bool loading = false;
  String msg = "";

  // Live validation error messages
  String usernameError = "";
  String passwordError = "";
  String emailError = "";
  String adminKeyError = "";

  // Email validation function
  bool isValidEmail(String email) {
    final pattern = r'^[\w-\.]+@(gmail|yahoo)\.(com|in)$';
    final regex = RegExp(pattern);
    return regex.hasMatch(email);
  }

  // Username validation
  bool isValidUsername(String username) {
    return username.length >= 3;
  }

  // Password validation
  bool isValidPassword(String password) {
    return password.length >= 6;
  }

  void register() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final email = _emailController.text.trim();
    final adminKey = _adminKeyController.text.trim();

    // Final validation before API call
    setState(() {
      usernameError = isValidUsername(username) ? "" : "Username must be at least 3 characters";
      passwordError = isValidPassword(password) ? "" : "Password must be at least 6 characters";
      emailError = isValidEmail(email) ? "" : "Email must be @gmail.com or @yahoo.in";
    });

    if (usernameError.isNotEmpty || passwordError.isNotEmpty || emailError.isNotEmpty) {
      return; // Stop if there are errors
    }

    setState(() {
      loading = true;
      msg = "";
    });

    try {
      final res = await ApiService.register(username, password, email, adminKey);

      setState(() => loading = false);

      if (res['success'] == true) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        setState(() => msg = res['message'] ?? "Registration failed");
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
      appBar: AppBar(title: Text("Register")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Username
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: "Username",
                errorText: usernameError.isEmpty ? null : usernameError,
              ),
              onChanged: (value) {
                setState(() {
                  usernameError = isValidUsername(value.trim()) ? "" : "Username must be at least 3 characters";
                });
              },
            ),
            SizedBox(height: 10),

            // Password
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                errorText: passwordError.isEmpty ? null : passwordError,
              ),
              onChanged: (value) {
                setState(() {
                  passwordError = isValidPassword(value.trim()) ? "" : "Password must be at least 6 characters";
                });
              },
            ),
            SizedBox(height: 10),

            // Email
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                errorText: emailError.isEmpty ? null : emailError,
              ),
              onChanged: (value) {
                setState(() {
                  emailError = isValidEmail(value.trim()) ? "" : "Email must be @gmail.com or @yahoo.in";
                });
              },
            ),
            SizedBox(height: 10),

            // Admin Key (optional)
            TextField(
              controller: _adminKeyController,
              decoration: InputDecoration(
                labelText: "Admin Key (optional)",
              ),
            ),
            SizedBox(height: 20),

            // Register Button
            loading
                ? CircularProgressIndicator()
                : ElevatedButton(onPressed: register, child: Text("Register")),

            SizedBox(height: 20),

            // General error message
            if (msg.isNotEmpty)
              Text(
                msg,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
           // Navigate to login
           TextButton(
      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
      child: Text("Already have an account? Login here"),
    ),

  
          ],
        ),
      ),
    );
  }
}
