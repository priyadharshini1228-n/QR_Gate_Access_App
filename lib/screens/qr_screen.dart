import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';

class QRScreen extends StatelessWidget {
  const QRScreen({super.key});

  Future<void> downloadQr(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Uint8List bytes = response.bodyBytes;
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/qr_code.png');
        await file.writeAsBytes(bytes);
        debugPrint('QR saved to ${file.path}');
      } else {
        debugPrint('Failed to download QR: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error downloading QR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Read arguments as Map
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    int? userId;
    if (args != null && args['user_id'] != null) {
      userId = args['user_id'] as int;
    }

    final qrUrl = userId != null ? ApiService.getQrUrl(userId) : "";

    return Scaffold(
      appBar: AppBar(title: const Text("Your QR Code")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            userId != null
                ? Image.network(
                    qrUrl,
                    height: 250,
                    width: 250,
                    errorBuilder: (context, error, stackTrace) => const Text(
                      "Failed to load QR",
                      style: TextStyle(color: Colors.red),
                    ),
                  )
                : const Text(
                    "No QR available",
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
            const SizedBox(height: 20),
            if (userId != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text("Download QR"),
                onPressed: () async {
                  await downloadQr(qrUrl);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("QR downloaded!")),
                  );
                },
              ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text("Back to Login"),
            ),
          ],
        ),
      ),
    );
  }
}
