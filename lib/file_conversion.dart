import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:firebase_storage/firebase_storage.dart';
import 'send_online_file_screen.dart';

class FileConversionPage extends StatefulWidget {
  const FileConversionPage({super.key});

  @override
  FileConversionPageState createState() => FileConversionPageState();
}

class FileConversionPageState extends State<FileConversionPage> {
  File? selectedFile;
  File? convertedFile;

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<File> saveFileInDownloads(Uint8List fileBytes, String fileName) async {
    if (await Permission.storage.request().isGranted) {
      final directory = Directory('/storage/emulated/0/Download');
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(fileBytes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("File saved at: ${file.path}")),
      );
      return file;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Storage permission denied")),
      );
      throw Exception("Storage permission denied");
    }
  }

  Future<void> convertJpgToPng() async {
    String? fileName = await _promptFileName();
    if (selectedFile != null && fileName != null && fileName.isNotEmpty) {
      final image = img.decodeImage(await selectedFile!.readAsBytes())!;
      final pngImage = img.encodePng(image);
      final file = await saveFileInDownloads(Uint8List.fromList(pngImage), "$fileName.png");
      setState(() => convertedFile = file);
      _confirmAndUpload(file);
    }
  }

  Future<void> convertPngToJpg() async {
    String? fileName = await _promptFileName();
    if (selectedFile != null && fileName != null && fileName.isNotEmpty) {
      final image = img.decodeImage(await selectedFile!.readAsBytes())!;
      final jpgImage = img.encodeJpg(image);
      final file = await saveFileInDownloads(Uint8List.fromList(jpgImage), "$fileName.jpg");
      setState(() => convertedFile = file);
      _confirmAndUpload(file);
    }
  }

  Future<void> convertImageToPdf() async {
    String? fileName = await _promptFileName();
    if (selectedFile != null && fileName != null && fileName.isNotEmpty) {
      final image = img.decodeImage(await selectedFile!.readAsBytes())!;
      final pdf = pw.Document();
      pdf.addPage(pw.Page(
        build: (pw.Context context) =>
            pw.Center(child: pw.Image(pw.MemoryImage(Uint8List.fromList(img.encodeJpg(image))))),
      ));
      final file = await saveFileInDownloads(await pdf.save(), "$fileName.pdf");
      setState(() => convertedFile = file);
      _confirmAndUpload(file);
    }
  }

  Future<void> convertTextToPdf() async {
    String? fileName = await _promptFileName();
    String? userInputText = await _promptUserText();
    if (fileName != null && fileName.isNotEmpty && userInputText != null && userInputText.isNotEmpty) {
      final pdf = pw.Document();
      pdf.addPage(pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Text(userInputText, style: pw.TextStyle(fontSize: 18)),
        ),
      ));
      final file = await saveFileInDownloads(await pdf.save(), "$fileName.pdf");
      setState(() => convertedFile = file);
      _confirmAndUpload(file);
    }
  }

  Future<void> _confirmAndUpload(File file) async {
    bool confirmed = await _showUploadConfirmationDialog();
    if (confirmed) {
      _navigateToSendScreen(file);
    }
  }

  Future<bool> _showUploadConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmation"),
          content: const Text("Do you want to upload the converted file?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Yes"),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<String?> _promptFileName() async {
    TextEditingController fileNameController = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Enter File Name"),
          content: TextField(
            controller: fileNameController,
            decoration: const InputDecoration(hintText: "File name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(fileNameController.text),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _promptUserText() async {
    TextEditingController textController = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Enter Text Content"),
          content: TextField(
            controller: textController,
            maxLines: 4,
            decoration: const InputDecoration(hintText: "Type your content here"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(textController.text),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _navigateToSendScreen(File file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SendOnlineFileScreen(initialFilePath: file.path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("File Conversion")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: pickFile,
                child: const Text("Choose File"),
              ),
              if (selectedFile != null)
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      "Selected File: ${selectedFile!.path.split('/').last}",
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ElevatedButton(
                onPressed: convertJpgToPng,
                child: const Text("Convert JPG to PNG"),
              ),
              ElevatedButton(
                onPressed: convertPngToJpg,
                child: const Text("Convert PNG to JPG"),
              ),
              ElevatedButton(
                onPressed: convertImageToPdf,
                child: const Text("Convert Image to PDF"),
              ),
              ElevatedButton(
                onPressed: convertTextToPdf,
                child: const Text("Convert Text to PDF"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
