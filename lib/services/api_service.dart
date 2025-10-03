import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://127.0.0.1:5000";
 // works on web

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> register(
      String username, String password, String email, String adminKey) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "password": password,
        "email": email,
        "admin_key": adminKey
      }),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> submitUserForm(Map<String, String> data) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/user_form"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static String getQrUrl(int userId) {
    return "$baseUrl/api/get_qr?user_id=$userId";
  }

  static Future<Map<String, dynamic>> verifyQr(String qrData, String logType) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/verify_qr"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"qr_data": qrData, "log_type": logType}),
    );
    return jsonDecode(res.body);
  }

  /// ✅ FIXED: Call correct endpoint
  static Future<Map<String, dynamic>> getAdminDashboardStats() async {
  final url = Uri.parse("$baseUrl/api/admin/dashboard");
  print("➡️ Fetching dashboard from: $url");

  final res = await http.get(url);
  print("⬅️ Response: ${res.statusCode} ${res.body}");

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception("Failed to load stats (code ${res.statusCode})");
  }
}

  //adminlogs
  static Future<List<Map<String, dynamic>>> getAdminLogs({
  String username = '',
  String logType = '',
  String startDate = '',
  String endDate = '',
  int page = 1,
  int perPage = 50,
}) async {
  final queryParams = {
    if (username.isNotEmpty) 'username': username,
    if (logType.isNotEmpty) 'log_type': logType,
    if (startDate.isNotEmpty) 'start_date': startDate,
    if (endDate.isNotEmpty) 'end_date': endDate,
    'page': page.toString(),
    'per_page': perPage.toString(),
  };
  final uri = Uri.parse("$baseUrl/api/admin/logs").replace(queryParameters: queryParams);
  final res = await http.get(uri);
  if (res.statusCode == 200) {
    final json = jsonDecode(res.body);
    if (json['success'] == true) {
      return List<Map<String, dynamic>>.from(json['logs']);
    } else {
      throw Exception('API returned success=false');
    }
  }
  throw Exception('Failed to fetch logs');
}
//registeredusers
static Future<List<dynamic>> fetchRegisteredUsers() async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/admin/users'),
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['data'] ?? []; // ✅ use 'data', not 'users'
  } else {
    throw Exception('Failed to fetch users');
  }
}

static Future<Map<String, dynamic>> verifyQR({
  required String qrData,
  required String logType,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/verify_qr'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "qr_data": qrData,
        "log_type": logType,
      }),
    );

    final Map<String, dynamic> data = json.decode(response.body);

    return {
      'success': response.statusCode == 200,
      'message': data['message'] ?? 'Unknown error',
      'gate_status': data['gate_status'] ?? 'unknown',
    };
  } catch (e) {
    return {'success': false, 'message': '❌ Error verifying QR: $e'};
  }
}


// request password
static Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    final url = Uri.parse("$baseUrl/request_password_reset");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    return jsonDecode(response.body);
  }
  //reset password
  static Future<Map<String, dynamic>> resetPassword(
      String token, String newPassword) async {
    final url = Uri.parse("$baseUrl/reset_password");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"token": token, "new_password": newPassword}),
    );

    return jsonDecode(response.body);
  }
  // weekly trend
  Future<Map<String, dynamic>> fetchWeeklyVisitors() async {
  final response = await http.get(
    Uri.parse("http://localhost:5000/api/admin/weekly_visitors"),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to fetch weekly visitors");
  }
}

}




































