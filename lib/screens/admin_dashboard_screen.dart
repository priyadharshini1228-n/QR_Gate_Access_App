import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:qr_gate_app/screens/admin/admin_reports_screen.dart';
import 'package:qr_gate_app/screens/admin/scan_screen.dart';
import 'package:qr_gate_app/screens/admin/users_screen.dart';
import 'package:qr_gate_app/screens/admin/workers_screen.dart';
//import 'package:qr_gate_app/screens/admin/users_screen.dart';
import 'package:qr_gate_app/screens/login_screen.dart';
import '../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool sidebarOpen = true;
  bool loading = true;
  String errorMsg = "";

  int weeklyVisitors = 0;
  int registeredUsers = 0;
  int registeredWorkers = 0;
  List<int> weeklyVisitorsTrend = [];
  List<String> dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  int selectedIndex = 0; // 0: Dashboard, 1: Reports, 2: QR Auth
  Timer? refreshTimer;

  final screens = [
    const DashboardContentScreen(),
    const ReportScreen(),
    const QRScanScreen(),
  ];

  @override
  void initState() {
    super.initState();
    fetchStats();
    refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchStats();
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchStats() async {
    try {
      final response = await ApiService.getAdminDashboardStats();
      if (response['success'] == true) {
        final stats = response['data'];
        setState(() {
          weeklyVisitors = stats['weekly_visitors'] ?? 0;
          registeredUsers = stats['registered_users'] ?? 0;
          registeredWorkers = stats['registered_workers'] ?? 0;
          weeklyVisitorsTrend =
              (stats['weekly_trend'] as List<dynamic>? ?? [])
                  .map((e) => e as int)
                  .toList();
          loading = false;
          errorMsg = "";
        });
      } else {
        setState(() {
          loading = false;
          errorMsg = "Failed: success=false";
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        errorMsg = "Failed to fetch stats: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7fc),
      body: Row(
        children: [
          // Sidebar
          if (sidebarOpen || MediaQuery.of(context).size.width > 568)
            _buildSidebar(context),

          // Main content
          Expanded(
            child: IndexedStack(
              index: selectedIndex,
              children: screens.map((screen) {
                if (screen is DashboardContentScreen) {
                  return _buildDashboardContent(context);
                }
                return screen;
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
  return Container(
    width: 160, // reduced from 240
    color: const Color(0xff5e60ce),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "⚡ Admin",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        const SizedBox(height: 20),
        navItem("Dashboard", Icons.dashboard, onTap: () {
          setState(() => selectedIndex = 0);
        }),
        navItem("Reports", Icons.bar_chart, onTap: () {
          setState(() => selectedIndex = 1);
        }),
        navItem("Authentication", Icons.security, onTap: () {
          setState(() => selectedIndex = 2);
        }),
        const Spacer(),
        navItem("Logout", Icons.logout, onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }),
      ],
    ),
  );
}


  Widget _buildDashboardContent(BuildContext context) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(30),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Welcome, Admin",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            if (MediaQuery.of(context).size.width <= 768)
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () {
                  setState(() {
                    sidebarOpen = !sidebarOpen;
                  });
                },
              )
          ],
        ),
        const SizedBox(height: 30),

        // Stat cards in Wrap
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            statCard(
              "Weekly Visitors",
              "$weeklyVisitors",
              Colors.pinkAccent,
              [Colors.pink.shade200, Colors.blue.shade200],
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RegisteredUsersScreen()),
                );
              },
              child: statCard(
                "Registered Users",
                "$registeredUsers",
                Colors.blueAccent,
                [Colors.blue.shade300, Colors.lightBlue.shade100],
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RegisteredWorkersScreen()),
                );
              },
              child: statCard(
                "Registered Workers",
                "$registeredWorkers",
                Colors.cyan,
                [Colors.cyan.shade200, Colors.blue.shade400],
              ),
            ),
          ],
        ),

        const SizedBox(height: 40),

                    // Line chart
                    _lineChart(
                        weeklyVisitorsTrend: weeklyVisitorsTrend,
                        dayLabels: dayLabels),

                    const SizedBox(height: 40),

                    // Pie Chart
                    _pieChart(),
                  ],
                ),
              );
  }

  Widget _lineChart(
      {required List<int> weeklyVisitorsTrend,
      required List<String> dayLabels}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Weekly Visitors Overview",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: true),
                borderData: FlBorderData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < dayLabels.length) {
                          return Text(dayLabels[index],
                              style: const TextStyle(fontSize: 12));
                        }
                        return const SizedBox.shrink();
                      },
                      interval: 1,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 1,
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                minX: 0,
                maxX: (weeklyVisitorsTrend.length - 1).toDouble(),
                minY: 0,
                maxY: (weeklyVisitorsTrend.isNotEmpty
                        ? weeklyVisitorsTrend.reduce((a, b) => a > b ? a : b)
                        : 10)
                    .toDouble(),
                lineBarsData: [
                  LineChartBarData(
                    spots: weeklyVisitorsTrend
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                        .toList(),
                    isCurved: true,
                    color: const Color(0xff5e60ce),
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xff5e60ce).withOpacity(0.2),
                    ),
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pieChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("User Distribution",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                      value: registeredUsers.toDouble(),
                      color: const Color(0xff5e60ce),
                      title: "Users"),
                  PieChartSectionData(
                      value: registeredWorkers.toDouble(),
                      color: const Color(0xff4cafef),
                      title: "Workers"),
                  PieChartSectionData(
                      value: 1,
                      color: const Color(0xffa1c4fd),
                      title: "Admins"),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 10,
        ),
      ],
    );
  }

  Widget navItem(String title, IconData icon, {VoidCallback? onTap}) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}


  Widget statCard(String title, String value, Color color, List<Color> gradient) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 5),
          const Text("Updated",
              style: TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}

// Placeholder dashboard content screen
class DashboardContentScreen extends StatelessWidget {
  const DashboardContentScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Dashboard Content"));
  }
}
