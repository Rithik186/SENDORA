// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FilePickerButton extends StatefulWidget {
  const FilePickerButton({super.key});

  @override
  _FilePickerButtonState createState() => _FilePickerButtonState();
}

class _FilePickerButtonState extends State<FilePickerButton> {
  String? _fileName;

  Future<void> _pickFile() async {
    // Open file picker
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      // Retrieve the selected file
      PlatformFile file = result.files.first;

      setState(() {
        _fileName = file.name; // Update file name state
      });
    } else {
      setState(() {
        _fileName = 'No file selected'; // Update state if no file is selected
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: _pickFile,
          child: const Text('Pick a File'),
        ),
        const SizedBox(height: 20),
        Text(
          _fileName ?? 'No file selected',
          style: const TextStyle(fontSize: 18),
        ),
      ],
    );
  }
}