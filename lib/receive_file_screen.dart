import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:udp/udp.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:wifi_iot/wifi_iot.dart';

class ReceiveFileScreen extends StatefulWidget {
  const ReceiveFileScreen({super.key});

  @override
  ReceiveFileScreenState createState() => ReceiveFileScreenState();
}

class ReceiveFileScreenState extends State<ReceiveFileScreen> {
  UDP? receiver;
  final int port = 65001;
  String statusMessage = "Waiting for files...";
  String? scannedSSID;
  String? scannedPassword;

  @override
  void initState() {
    super.initState();
    initReceiver();
  }

  Future<void> initReceiver() async {
    receiver = await UDP.bind(Endpoint.any(port: Port(port)));
    setState(() {
      statusMessage = "Receiver initialized on port: $port";
    });
    listenForFiles();
  }

  Future<void> listenForFiles() async {
    if (receiver != null) {
      receiver!.socket?.listen((event) {
        if (event == RawSocketEvent.read) {
          receiver!.socket!.receive()?.then((datagram) {
            if (datagram != null) {
              final fileData = datagram.data;
              String fileName = 'received_file_${DateTime.now().millisecondsSinceEpoch}.dat';
              _saveFile(fileData, fileName);
            }
          });
        }
      });
    }
  }

  Future<void> _saveFile(List<int> fileData, String fileName) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String filePath = '${appDocDir.path}/$fileName';
    File file = File(filePath);
    try {
      await file.writeAsBytes(fileData);
      setState(() {
        statusMessage = "File received and saved as $fileName";
      });
    } catch (e) {
      setState(() {
        statusMessage = "Error saving file: $e";
      });
    }
  }

  Future<void> scanQRCode() async {
    String qrResult = await FlutterBarcodeScanner.scanBarcode(
      "#ff6666", "Cancel", false, ScanMode.QR);
    
    if (qrResult != "-1") {
      var regex = RegExp(r'S:(.*?);T:WPA;P:(.*?);');
      var match = regex.firstMatch(qrResult);
      if (match != null) {
        setState(() {
          scannedSSID = match.group(1);
          scannedPassword = match.group(2);
          statusMessage = "Scanned SSID: $scannedSSID, Password: $scannedPassword";
        });
        await connectToWiFi(scannedSSID!, scannedPassword!);
      } else {
        setState(() {
          statusMessage = "Invalid QR code.";
        });
      }
    }
  }

  Future<void> connectToWiFi(String ssid, String password) async {
    try {
      bool isConnected = await WiFiForIoTPlugin.connect(ssid, password: password, security: NetworkSecurity.WPA);
      if (isConnected) {
        setState(() {
          statusMessage = "Connected to $ssid";
        });
      } else {
        setState(() {
          statusMessage = "Failed to connect to $ssid";
        });
      }
    } catch (e) {
      setState(() {
        statusMessage = "Error connecting to Wi-Fi: $e";
      });
    }
  }

  @override
  void dispose() {
    receiver?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receive File')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(statusMessage),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: scanQRCode,
              child: const Text('Scan QR Code'),
            ),
          ],
        ),
      ),
    );
  }
}

extension on Datagram? {
  void then(Null Function(dynamic datagram) param0) {}
}
