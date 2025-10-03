import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_code_tools/qr_code_tools.dart';
import 'package:qr_gate_app/services/api_service.dart';
import 'package:lottie/lottie.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  String resultMessage = "";
  bool isSuccess = false;
  String logType = "entry"; // default
  XFile? pickedImage;
  final TextEditingController qrController = TextEditingController();

  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          pickedImage = image;
          resultMessage = "Decoding QR...";
          isSuccess = false;
        });

        String? qrText;

        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          // Decode QR from image on mobile
          qrText = await QrCodeToolsPlugin.decodeFrom(image.path);
        } else {
          // Web/Desktop: fallback to manual text entry
          qrText = qrController.text.isNotEmpty ? qrController.text : null;
        }

        if (qrText != null && qrText.isNotEmpty) {
          verifyQR(qrText); // ✅ fixed function name
        } else {
          setState(() {
            resultMessage = "❌ Unable to decode QR. Please paste QR text.";
            isSuccess = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        resultMessage = "❌ Error picking/decoding image: $e";
        isSuccess = false;
      });
    }
  }

  Future<void> verifyQR(String qrText) async {
    try {
      final response = await ApiService.verifyQR(qrData: qrText, logType: logType);

      if (response['success'] == true) {
        // Pick animation based on logType
        String animation = logType == "entry"
            ? 'assets/animations/gate_open.json'
            : 'assets/animations/gate_close.json';

        String title = logType == "entry" ? "Gate Opening 🚪" : "Gate Closing 🚪";

        // ✅ Show gate animation in dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  animation,
                  width: 200,
                  height: 200,
                  repeat: false,
                ),
                const SizedBox(height: 10),
                Text(
                  response['message'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text("Close"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      } else {
        // ❌ Invalid QR
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ${response['message']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error verifying QR: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("QR Verification")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Log type toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Radio<String>(
                  value: "entry",
                  groupValue: logType,
                  onChanged: (val) => setState(() => logType = val!),
                ),
                const Text("Entry"),
                const SizedBox(width: 20),
                Radio<String>(
                  value: "exit",
                  groupValue: logType,
                  onChanged: (val) => setState(() => logType = val!),
                ),
                const Text("Exit"),
              ],
            ),

            const SizedBox(height: 20),

            // Web/Desktop: Paste QR text manually
            if (kIsWeb ||
                Platform.isWindows ||
                Platform.isLinux ||
                Platform.isMacOS)
              Column(
                children: [
                  TextField(
                    controller: qrController,
                    decoration: const InputDecoration(
                      labelText: "Paste QR text here",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (qrController.text.isNotEmpty) {
                        verifyQR(qrController.text);
                      } else {
                        setState(() {
                          resultMessage = "❌ Please paste QR text";
                          isSuccess = false;
                        });
                      }
                    },
                    child: const Text("Verify QR"),
                  ),
                  const SizedBox(height: 20),
                ],
              ),

            // Upload image button (works on mobile)
            ElevatedButton(
              onPressed: pickImage,
              child: const Text("Upload QR Image"),
            ),

            const SizedBox(height: 30),

            // Result
            Text(
              resultMessage,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSuccess ? Colors.green : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
