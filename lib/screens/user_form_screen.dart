import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UserFormScreen extends StatefulWidget {
  const UserFormScreen({super.key});

  @override
  _UserFormScreenState createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> formData = {};
  bool loading = false;
  String msg = "";

  late int userId; // store userId passed from login

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && args['userId'] != null) {
      userId = args['userId'];
      formData['user_id'] = userId.toString(); // pass userId to API
    }
  }

  void submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() {
      loading = true;
      msg = "";
    });

    try {
      final res = await ApiService.submitUserForm(formData);

      setState(() => loading = false);

      if (res['success']) {
        Navigator.pushReplacementNamed(
          context,
          '/qr_screen',
          arguments: {"user_id": userId}, // pass userId to QR screen
        );
      } else {
        setState(() => msg = res['message'] ?? "Failed to submit form");
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
      appBar: AppBar(title: const Text("Complete Your Details")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: "First Name"),
                  onSaved: (val) => formData['fname'] = val ?? "",
                  validator: (val) => val!.isEmpty ? "Enter first name" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: "Last Name"),
                  onSaved: (val) => formData['lname'] = val ?? "",
                  validator: (val) => val!.isEmpty ? "Enter last name" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: "Gender"),
                  onSaved: (val) => formData['gender'] = val ?? "",
                  validator: (val) => val!.isEmpty ? "Enter gender" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: "Contact Number"),
                  keyboardType: TextInputType.phone,
                  onSaved: (val) => formData['contact_number'] = val ?? "",
                  validator: (val) => val!.isEmpty ? "Enter contact number" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: "Email ID"),
                  keyboardType: TextInputType.emailAddress,
                  onSaved: (val) => formData['email_id'] = val ?? "",
                  validator: (val) => val!.isEmpty ? "Enter email" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: "Address"),
                  maxLines: 3,
                  onSaved: (val) => formData['address'] = val ?? "",
                  validator: (val) => val!.isEmpty ? "Enter address" : null,
                ),
                const SizedBox(height: 20),
                loading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: submitForm,
                        child: const Text("Submit"),
                      ),
                const SizedBox(height: 20),
                if (msg.isNotEmpty)
                  Text(
                    msg,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
