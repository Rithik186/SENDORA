import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';

class ReceiveFileScreen extends StatefulWidget {
  const ReceiveFileScreen({super.key});

  @override
  ReceiveFileScreenState createState() => ReceiveFileScreenState();
}

class ReceiveFileScreenState extends State<ReceiveFileScreen> {
  static const platform = MethodChannel('com.example.sendora/wifi_direct');
  String ssid = '';
  String password = '';
  String qrData = '';
  String connectionStatus = 'Not Connected'; // Track connection status

  @override
  void initState() {
    super.initState();
    generateQRCode(); // Generate QR code when the screen loads
  }

  // Method to generate the QR code with dynamic network details
  Future<void> generateQRCode() async {
    try {
      final result = await platform.invokeMethod<Map>('generateNetworkDetails');
      if (result != null) {
        setState(() {
          ssid = result['ssid'];
          password = result['password'];
          qrData = "SSID:$ssid;PASSWORD:$password";
        });
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to generate network details: ${e.message}");
    }
  }

  // Automatically connect to the sender when QR code is scanned
  Future<void> connectToPeer() async {
    try {
      // Automatically connect to the peer after scanning the QR code
      final result = await platform.invokeMethod('connectToPeer', {'ssid': ssid, 'password': password});
      if (result == 'success') {
        setState(() {
          connectionStatus = 'Connected to $ssid';
        });
      } else {
        setState(() {
          connectionStatus = 'Failed to connect';
        });
      }
    } catch (e) {
      setState(() {
        connectionStatus = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receive File')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Scan this QR Code to connect:'),
            const SizedBox(height: 20),
            if (qrData.isNotEmpty)
              QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200.0,
              ),
            const SizedBox(height: 20),
            Text('SSID: $ssid'),
            Text('Password: $password'),
            const SizedBox(height: 20),
            Text('Connection Status: $connectionStatus'), // Display connection status
          ],
        ),
      ),
    );
  }
}
