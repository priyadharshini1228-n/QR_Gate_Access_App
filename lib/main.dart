import 'package:flutter/material.dart';
import 'package:qr_gate_app/Password/forgot_password.dart';
import 'package:qr_gate_app/Password/reset_password.dart';
import 'package:qr_gate_app/screens/admin_dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/user_form_screen.dart';
import 'screens/qr_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Gate App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login', // Start with Login Screen
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/user_form': (context) => UserFormScreen(),
        '/qr_screen': (context) => QRScreen(),
        '/admin_dashboard': (context) => const AdminDashboardScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/reset_password': (context) => const ResetPasswordScreen(),
      },
    );
  }
}
