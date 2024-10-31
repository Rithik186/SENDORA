import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class SendFileScreen extends StatefulWidget {
  const SendFileScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SendFileScreenState createState() => _SendFileScreenState();
}

class _SendFileScreenState extends State<SendFileScreen> {
  final Logger logger = Logger();
  String hotspotDetails = '';

  @override
  void initState() {
    super.initState();
    _createHotspot();
  }

  Future<void> _createHotspot() async {
    const platform = MethodChannel('com.example.sendora/wifi');

    try {
      final String result = await platform.invokeMethod('startHotspot');
      setState(() {
        hotspotDetails = result; // result contains SSID, password, and IP
      });
    } on PlatformException catch (e) {
      logger.e("Failed to start hotspot: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Files'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hotspotDetails.isNotEmpty)
              Column(
                children: [
                  Text(
                    'Hotspot Details:',
                    style: Theme.of(context).textTheme.titleMedium, // Use titleMedium instead of headline6
                  ),
                  const SizedBox(height: 10),
                  BarcodeWidget(
                    data: hotspotDetails, // SSID, password, and IP for QR code
                    barcode: Barcode.qrCode(),
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 20),
                  Text(hotspotDetails, textAlign: TextAlign.center),
                ],
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Implement file selection and sending logic
              },
              child: const Text('Select Files to Send'),
            ),
          ],
        ),
      ),
    );
  }
}
