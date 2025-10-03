import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisteredWorkersScreen extends StatefulWidget {
  const RegisteredWorkersScreen({super.key});

  @override
  _RegisteredWorkersScreenState createState() => _RegisteredWorkersScreenState();
}

class _RegisteredWorkersScreenState extends State<RegisteredWorkersScreen> {
  List<dynamic> workers = [];
  List<dynamic> filteredWorkers = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchWorkers();
    searchController.addListener(_filterWorkers);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchWorkers() async {
    setState(() => isLoading = true);
    try {
      final response =
          await http.get(Uri.parse("http://127.0.0.1:5000/api/admin/workers"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          workers = data["data"] ?? [];
          filteredWorkers = workers;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching workers: $e");
      setState(() => isLoading = false);
    }
  }

  void _filterWorkers() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredWorkers = workers.where((worker) {
        final name = (worker?["name"] ?? "").toLowerCase();
        final email = (worker?["email"] ?? "").toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Search workers...",
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchWorkers,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    filteredWorkers.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.only(top: 50),
                            child: Text("No workers found"),
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
                                DataColumn(label: Text("Worker ID")),
                                DataColumn(label: Text("Name")),
                                DataColumn(label: Text("Email")),
                              ],
                              rows: List.generate(filteredWorkers.length, (index) {
                                final worker = filteredWorkers[index];
                                final bgColor =
                                    index % 2 == 0 ? Colors.grey[50] : Colors.white;
                                return DataRow(
                                  color: WidgetStateProperty.all(bgColor),
                                  cells: [
                                    DataCell(Text((index + 1).toString())),
                                    DataCell(Text((worker?["worker_id"] ?? "N/A").toString())),
                                    DataCell(Text(worker?["name"] ?? "N/A")),
                                    DataCell(Text(worker?["email"] ?? "N/A")),
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
