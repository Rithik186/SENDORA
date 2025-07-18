import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';

class SendOnlineFileScreen extends StatefulWidget {
  final String? initialFilePath;

  const SendOnlineFileScreen({super.key, this.initialFilePath});

  @override
  SendOnlineFileScreenState createState() => SendOnlineFileScreenState();
}

class SendOnlineFileScreenState extends State<SendOnlineFileScreen> {
  List<Map<String, dynamic>> _fileUploadHistory = [];
  final List<String> _currentDownloadUrls = []; // Stores the download URLs for all uploaded files
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUploadHistory();
    if (widget.initialFilePath != null) {
      _uploadFile(File(widget.initialFilePath!));
    }
  }

  Future<void> _loadUploadHistory() async {
    try {
      final path = await _getHistoryFilePath();
      final file = File(path);

      if (await file.exists()) {
        final content = await file.readAsString();
        final history = jsonDecode(content) as List;
        setState(() {
          _fileUploadHistory = history.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Failed to load upload history: $e');
    }
  }

  Future<String> _getHistoryFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/upload_history.json';
  }

  Future<void> _saveUploadHistory() async {
    try {
      final path = await _getHistoryFilePath();
      final file = File(path);
      final content = jsonEncode(_fileUploadHistory);
      await file.writeAsString(content);
    } catch (e) {
      debugPrint('Failed to save upload history: $e');
    }
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null) {
      setState(() {
        _isUploading = true;
      });

      List<File> files = result.paths.map((path) {
        if (path != null) {
          return File(path);
        } else {
          throw Exception("Invalid file path.");
        }
      }).toList();

      for (var file in files) {
        _uploadFile(file);
      }
    }
  }

  Future<void> _uploadFile(File file) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = FirebaseStorage.instance.ref().child('user_uploads/$fileName');
      UploadTask uploadTask = storageRef.putFile(file);

      // Add the file to history with "Uploading" status
      setState(() {
        _fileUploadHistory.add({
          'fileName': file.uri.pathSegments.last,
          'status': 'Uploading 0%',
          'url': null,
          'error': null,
        });
      });

      // Listen for upload progress and update status
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = ((snapshot.bytesTransferred / snapshot.totalBytes) * 100).toStringAsFixed(0);
        setState(() {
          final index = _fileUploadHistory.indexWhere((entry) => entry['fileName'] == file.uri.pathSegments.last);
          if (index != -1) {
            _fileUploadHistory[index]['status'] = 'Uploading $progress%';
          }
        });
      });

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        final index = _fileUploadHistory.indexWhere((entry) => entry['fileName'] == file.uri.pathSegments.last);
        if (index != -1) {
          _fileUploadHistory[index]['status'] = 'Completed';
          _fileUploadHistory[index]['url'] = downloadUrl;
        }
        _currentDownloadUrls.add(downloadUrl); // Add the current URL to the list
      });

      await _saveUploadHistory();
    } catch (e) {
      setState(() {
        _fileUploadHistory.add({
          'fileName': file.uri.pathSegments.last,
          'status': 'Failed',
          'url': null,
          'error': e.toString(),
        });
      });

      await _saveUploadHistory();
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _retryUpload(File file) {
    setState(() {
      _fileUploadHistory.removeWhere((entry) => entry['fileName'] == file.uri.pathSegments.last);
    });
    _uploadFile(file);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Online File'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Upload History',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            if (_fileUploadHistory.isEmpty)
              const ListTile(
                title: Text('No uploads yet'),
              )
            else
              ..._fileUploadHistory.map((fileEntry) {
                return ListTile(
                  title: Text(fileEntry['fileName']),
                  subtitle: Text(fileEntry['status']),
                  trailing: fileEntry['status'] == 'Failed'
                      ? ElevatedButton(
                          onPressed: () {
                            File file = File(fileEntry['fileName']);
                            _retryUpload(file);
                          },
                          child: const Text('Retry'),
                        )
                      : fileEntry['url'] != null
                          ? ElevatedButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: fileEntry['url']));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Download URL copied to clipboard!')),
                                );
                              },
                              child: const Text('Copy URL'),
                            )
                          : null,
                  onTap: fileEntry['url'] != null
                      ? () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Download QR Code'),
                                content: QrImageView(
                                  data: fileEntry['url']!,
                                  version: QrVersions.auto,
                                  size: 200.0,
                                ),
                              );
                            },
                          );
                        }
                      : null,
                );
              }).toList(),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isUploading)
              const CircularProgressIndicator()
            else ...[
              if (_currentDownloadUrls.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('Current File QR Codes:'),
                      ..._currentDownloadUrls.map((url) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: QrImageView(
                            data: url,
                            version: QrVersions.auto,
                            size: 200.0,
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ElevatedButton(
                onPressed: _pickFiles,
                child: const Text('Pick and Upload Files'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
