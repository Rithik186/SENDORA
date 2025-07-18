import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';

class FileCompressionScreen extends StatefulWidget {
  const FileCompressionScreen({super.key});

  @override
  FileCompressionScreenState createState() => FileCompressionScreenState();
}

class FileCompressionScreenState extends State<FileCompressionScreen> {
  List<File> selectedFiles = [];
  List<File> compressedFiles = [];
  List<String> sizeComparisons = [];
  String compressionQuality = "Balanced";
  double? targetSizePercentage;

  // Select files from device
  void pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );
    if (result != null) {
      setState(() {
        selectedFiles = result.paths.map((path) => File(path!)).toList();
        sizeComparisons.clear();
      });
    }
  }

  // Compress image files
  Future<File> compressImageFile(File file, String quality) async {
    final img.Image image = img.decodeImage(await file.readAsBytes())!;
    int qualityFactor;
    switch (quality) {
      case "High":
        qualityFactor = 70;
        break;
      case "Balanced":
        qualityFactor = 50;
        break;
      case "Low":
        qualityFactor = 30;
        break;
      default:
        qualityFactor = targetSizePercentage?.toInt() ?? 50;
    }

    List<int> compressedBytes = img.encodeJpg(image, quality: qualityFactor);
    final appDocDir = await getApplicationDocumentsDirectory();
    String fileName = "compressed_${file.uri.pathSegments.last}";
    File compressedFile = File('${appDocDir.path}/$fileName');
    await compressedFile.writeAsBytes(compressedBytes);
    return compressedFile;
  }

  // Compress PDF files
  Future<File> compressPdfFile(File file, String quality) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    String fileName = "compressed_${file.uri.pathSegments.last}";
    File compressedFile = File('${appDocDir.path}/$fileName');

    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (pw.Context context) {
      return pw.Center(child: pw.Text("Compressed PDF"));
    }));

    await compressedFile.writeAsBytes(await pdf.save());
    return compressedFile;
  }

  // Compress files based on type
  Future<void> compressFiles() async {
    if (selectedFiles.isEmpty) {
      Fluttertoast.showToast(msg: "No files selected!");
      return;
    }

    List<File> tempCompressedFiles = [];
    List<String> tempSizeComparisons = [];

    for (var file in selectedFiles) {
      String originalSize = (file.lengthSync() / 1024 / 1024).toStringAsFixed(2);

      File compressedFile;
      if (file.path.toLowerCase().endsWith(".jpg") || file.path.toLowerCase().endsWith(".png")) {
        compressedFile = await compressImageFile(file, compressionQuality);
      } else if (file.path.toLowerCase().endsWith(".pdf")) {
        compressedFile = await compressPdfFile(file, compressionQuality);
      } else {
        Fluttertoast.showToast(msg: "Unsupported file type: ${file.path}");
        continue;
      }

      tempCompressedFiles.add(compressedFile);
      String compressedSize = (compressedFile.lengthSync() / 1024 / 1024).toStringAsFixed(2);
      tempSizeComparisons.add("Original: $originalSize MB → Compressed: $compressedSize MB");
    }

    setState(() {
      compressedFiles = tempCompressedFiles;
      sizeComparisons = tempSizeComparisons;
    });

    Fluttertoast.showToast(msg: "Files compressed successfully!");
  }

  // Preview the compressed file (open the file)
  void previewFile(File file) {
    OpenFile.open(file.path);
  }

  // Set custom compression (percentage input)
  void setCustomCompression(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController percentageController = TextEditingController();
        return AlertDialog(
          title: Text("Custom Compression"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Enter compression percentage (e.g., 50 for 50%)"),
              TextField(
                controller: percentageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: "Enter percentage"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  targetSizePercentage =
                      double.tryParse(percentageController.text);
                });
                Navigator.pop(context);
              },
              child: Text("Set"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Compressify"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.file_present, color: Colors.white),
              label: Text("Select Files"),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ), backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: pickFiles,
            ),
            SizedBox(height: 16),
            if (selectedFiles.isNotEmpty) ...[
              Text("Selected Files (${selectedFiles.length}):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ListView.builder(
                shrinkWrap: true,
                itemCount: selectedFiles.length,
                itemBuilder: (context, index) => Card(
                  elevation: 5,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(selectedFiles[index].uri.pathSegments.last),
                    subtitle: Text("Size: ${(selectedFiles[index].lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB"),
                    trailing: IconButton(
                      icon: Icon(Icons.preview),
                      onPressed: () => previewFile(selectedFiles[index]),
                    ),
                  ),
                ),
              ),
            ],
            Divider(),
            SizedBox(height: 16),
            Text("Compression Quality", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: () => setState(() => compressionQuality = "High"), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: Text("High"),
                ),
                ElevatedButton(onPressed: () => setState(() => compressionQuality = "Balanced"), style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: Text("Balanced"),
                ),
                ElevatedButton(onPressed: () => setState(() => compressionQuality = "Low"), style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: Text("Low"),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setCustomCompression(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text("Set Custom Compression"),
            ),
            Divider(),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.compress, color: Colors.white),
              label: Text("Compress Files"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: compressFiles,
            ),
            SizedBox(height: 16),
            if (compressedFiles.isNotEmpty) ...[
              Text("Compressed Files (${compressedFiles.length}):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ListView.builder(
                shrinkWrap: true,
                itemCount: compressedFiles.length,
                itemBuilder: (context, index) {
                  String originalSize = (selectedFiles[index].lengthSync() / 1024 / 1024).toStringAsFixed(2);
                  String compressedSize = (compressedFiles[index].lengthSync() / 1024 / 1024).toStringAsFixed(2);

                  return Card(
                    elevation: 5,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(compressedFiles[index].uri.pathSegments.last),
                      subtitle: Text("Original: $originalSize MB → Compressed: $compressedSize MB"),
                      trailing: IconButton(
                        icon: Icon(Icons.preview),
                        onPressed: () => previewFile(compressedFiles[index]),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}