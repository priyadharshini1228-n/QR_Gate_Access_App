import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisteredUsersScreen extends StatefulWidget {
  const RegisteredUsersScreen({super.key});

  @override
  _RegisteredUsersScreenState createState() => _RegisteredUsersScreenState();
}

class _RegisteredUsersScreenState extends State<RegisteredUsersScreen> {
  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUsers();
    searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final response =
          await http.get(Uri.parse("http://127.0.0.1:5000/api/admin/users"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          users = data["data"] ?? [];
          filteredUsers = users;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching users: $e");
      setState(() => isLoading = false);
    }
  }

  void _filterUsers() {
  String query = searchController.text.toLowerCase();
  setState(() {
    filteredUsers = users.where((user) {
      final fname = (user?["fname"] ?? "").toLowerCase();
      final lname = (user?["lname"] ?? "").toLowerCase();
      final fullName = "$fname $lname".trim();
      final email = (user?["email_id"] ?? "").toLowerCase();
      final contact = (user?["contact_number"]?.toString() ?? "").toLowerCase();
      final address = (user?["address"] ?? "").toLowerCase();

      return fullName.contains(query) ||
          email.contains(query) ||
          contact.contains(query) ||
          address.contains(query);
    }).toList();
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light background for the page
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Search users...",
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchUsers,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    filteredUsers.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.only(top: 50),
                            child: Text("No users found"),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor:
                                  WidgetStateColor.resolveWith((states) => Colors.blue[200]!),
                              dataRowColor: WidgetStateColor.resolveWith((states) {
                                return states.contains(WidgetState.selected)
                                    ? Colors.blue[100]!
                                    : Colors.white;
                              }),
                              headingTextStyle: const TextStyle(
                                  fontWeight: FontWeight.bold, color: Colors.black),
                              columns: const [
                                DataColumn(label: Text("SI.No")),
                                DataColumn(label: Text("User ID")),
                                DataColumn(label: Text("First Name")),
                                DataColumn(label: Text("Last Name")),
                                //DataColumn(label: Text("Contact")),
                                DataColumn(label: Text("Address")),
                                DataColumn(label: Text("Email")),
                              ],
                              rows: List.generate(filteredUsers.length, (index) {
                                final user = filteredUsers[index];
                                final bgColor =
                                    index % 2 == 0 ? Colors.grey[50] : Colors.white;
                                return DataRow(
                                  color: WidgetStateProperty.all(bgColor),
                                  cells: [
                                    DataCell(Text((index + 1).toString())),
                                    DataCell(Text((user?["user_id"] ?? "N/A").toString())),
                                    DataCell(Text(user?["fname"] ?? "N/A")),
                                    DataCell(Text(user?["lname"] ?? "N/A")),
                                    //DataCell(Text(user?["contact_number"] ?? "N/A")),
                                    DataCell(Text(user?["address"] ?? "N/A")),
                                    DataCell(Text(user?["email_id"] ?? "N/A")),
                                  ],
                                );
                              }),
                            ),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
