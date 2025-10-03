import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController usernameController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  String logType = '';

  List<Map<String, dynamic>> logs = [];
  bool loading = true;
  String errorMsg = "";

  @override
  void initState() {
    super.initState();
    fetchLogs();
  }

  Future<void> fetchLogs() async {
    setState(() {
      loading = true;
      errorMsg = "";
    });

    try {
      final result = await ApiService.getAdminLogs(
        username: usernameController.text,
        logType: logType,
        startDate: startDate?.toIso8601String().split('T')[0] ?? '',
        endDate: endDate?.toIso8601String().split('T')[0] ?? '',
      );
      setState(() {
        logs = result;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorMsg = "Failed to fetch logs";
      });
    }
  }

  void resetFilters() {
    setState(() {
      usernameController.clear();
      startDate = null;
      endDate = null;
      logType = '';
    });
    fetchLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text("Reports")),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username or Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => startDate = picked);
                    },
                    child: Text(startDate == null
                        ? 'Start Date'
                        : startDate!.toLocal().toString().split(' ')[0]),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => endDate = picked);
                    },
                    child: Text(endDate == null
                        ? 'End Date'
                        : endDate!.toLocal().toString().split(' ')[0]),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: logType.isEmpty ? null : logType,
                    hint: const Text("Log Type"),
                    items: const [
                      DropdownMenuItem(value: 'entry', child: Text('Entry')),
                      DropdownMenuItem(value: 'exit', child: Text('Exit')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        logType = value ?? '';
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(onPressed: fetchLogs, child: const Text("Filter")),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: resetFilters,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: const Text("Reset"),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Registered Users & Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Logs table
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : errorMsg.isNotEmpty
                    ? Center(
                        child: Text(errorMsg, style: const TextStyle(color: Colors.red)),
                      )
                    : logs.isEmpty
                        ? const Center(child: Text("No logs found"))
                        : Scrollbar(
                            thumbVisibility: true,
                            trackVisibility: true,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: MediaQuery.of(context).size.width,
                                ),
                                child: DataTable(
                                  headingRowColor:
                                      MaterialStateProperty.all(Colors.blue.shade100),
                                  columns: const [
                                    DataColumn(label: Text("SI.No")),
                                    DataColumn(label: Text('User ID')),
                                    DataColumn(label: Text('Username')),
                                    DataColumn(label: Text('Email')),
                                    DataColumn(label: Text('Is Admin')),
                                    DataColumn(label: Text('Event Type')),
                                    DataColumn(label: Text('Entry Time')),
                                  ],
                                  rows: logs.asMap().entries.map((entry) {
                                    int index = entry.key;
                                    var log = entry.value;
                                    return DataRow(cells: [
                                      DataCell(Text((index + 1).toString())),
                                      DataCell(Text(log['user_id'].toString())),
                                      DataCell(Text(log['username'] ?? '')),
                                      DataCell(Text(log['email_id'] ?? '')),
                                      DataCell(Text(log['is_admin'] == 1 ? 'Yes' : 'No')),
                                      DataCell(Text(log['log_type'] ?? '')),
                                      DataCell(Text(log['entry_time'] ?? '')),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
