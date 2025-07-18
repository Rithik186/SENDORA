import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/services.dart';

class SendFileScreen extends StatefulWidget {
  const SendFileScreen({super.key});

  @override
  SendFileScreenState createState() => SendFileScreenState();
}

class SendFileScreenState extends State<SendFileScreen> {
  static const platform = MethodChannel('com.example.sendora/wifi_direct');
  List<String> selectedFiles = [];
  String transferStatus = '';

  // Method to select files
  Future<void> selectFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        selectedFiles = result.paths.map((path) => path!).toList();
      });
    }
  }

  // Method to scan QR code and handle connection
  Future<void> scanQRCode() async {
    try {
      final result = await BarcodeScanner.scan();
      setState(() {
        transferStatus = 'Scanned: ${result.rawContent}';
      });

      if (result.rawContent.startsWith("SSID:") && result.rawContent.contains("PASSWORD:")) {
        final ssid = result.rawContent.split(';').first.split(':').last.trim();
        final password = result.rawContent.split(';').last.split(':').last.trim();

        await connectToPeer(ssid, password);
      } else {
        setState(() {
          transferStatus = 'Invalid QR code scanned.';
        });
      }
    } catch (e) {
      setState(() {
        transferStatus = 'Failed to scan QR code: $e';
      });
    }
  }

  // Method to connect to the peer via Wi-Fi Direct
  Future<void> connectToPeer(String ssid, String password) async {
    try {
      await platform.invokeMethod('connectToPeer', {'ssid': ssid, 'password': password});
      setState(() {
        transferStatus = 'Connecting to $ssid...';
      });
    } catch (e) {
      setState(() {
        transferStatus = 'Failed to connect: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send File')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: selectFiles,
              child: const Text('Select File'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: selectedFiles.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(selectedFiles[index]),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: scanQRCode,
              child: const Text('Scan QR Code'),
            ),
            Text(transferStatus),
          ],
        ),
      ),
    );
  }
}
