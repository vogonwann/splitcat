import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:splitcat/util/catppuccin.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../util/split_merge.dart';

class QrCodeReadScreen extends StatefulWidget {
  const QrCodeReadScreen({super.key});

  @override
  _QrCodeScreenReadState createState() => _QrCodeScreenReadState();
}

class _QrCodeScreenReadState extends State<QrCodeReadScreen> {
  String? selectedFileName;
  String? selectedFilePath;
  IconData? selectedFileIcon;
  bool isSplitting = false;
  bool isDownloading = false; // Indikator preuzimanja
  double downloadProgress = 0.0; // Procenat preuzimanja
  bool zipBefore = false;
  final TextEditingController _sizeController = TextEditingController();
  String currentMessage = '';
  FilePickerResult selectedFile = FilePickerResult([]);
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void dispose() {
    _sizeController.dispose();
    super.dispose();
  }

  Future<void> downloadFile(String url, String savePath) async {
    setState(() {
      isDownloading = true;
      downloadProgress = 0.0;
    });

    final request = http.Request('GET', Uri.parse(url));
    final response = await request.send();

    if (response.statusCode == 200) {
      final file = File(savePath);
      final totalBytes = response.contentLength;
      int receivedBytes = 0;

      await response.stream.listen((value) {
        receivedBytes += value.length;
        setState(() {
          downloadProgress = totalBytes != null ? receivedBytes / totalBytes : 0;
        });
      }).asFuture();

      await file.writeAsBytes(await response.stream.toBytes());
      print("Fajl preuzet i sačuvan na $savePath");
    } else {
      print("Greška prilikom preuzimanja fajla: ${response.statusCode}");
    }

    setState(() {
      isDownloading = false;
    });
  }

  Future<void> onQRViewCreated(QRViewController controller) async {
    controller.scannedDataStream.listen((scanData) {
      // Ovdje možete obraditi skenirane podatke
      // npr. preuzimanje fajla
      var outputFile = await FilePicker.platform.saveFile(dialogTitle: "Choose location to save", fileName: "splitcat_${DateTime.now().microsecondsSinceEpoch}.zip");
      downloadFile(scanData.code!, outputFile!); // zamenite sa pravim putem
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Share via QR Code'),
      ),
      body: Stack(
        children: [
          Center(
            child: isDownloading
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(value: downloadProgress),
                SizedBox(height: 12),
                Text('${(downloadProgress * 100).toStringAsFixed(0)}% preuzeto'),
              ],
            )
                : SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    ),
                    onPressed: () async {
                      var result = await FilePicker.platform.pickFiles(allowMultiple: false);
                      if (result != null) {
                        setState(() {
                          selectedFile = result;
                          selectedFileIcon = Icons.insert_drive_file;
                        });
                      }
                    },
                    child: Text("Select file"),
                  ),
                  if (selectedFile.files.isNotEmpty)
                    ListTile(
                      leading: Icon(selectedFileIcon),
                      title: Text(selectedFile.files.first.name),
                    ),
                  SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    ),
                    onPressed: () {
                      shareFiles(selectedFile, context, (splitting) {
                        setState(() {
                          isSplitting = splitting;
                        });
                      }, (message) {
                        setState(() {
                          currentMessage = message;
                        });
                      }, zipBefore: true);
                    },
                    child: const Text('Send File'),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    ),
                    onPressed: () {
                      shareFiles(selectedFile, context, (splitting) {
                        setState(() {
                          isSplitting = splitting;
                        });
                      }, (message) {
                        setState(() {
                          currentMessage = message;
                        });
                      }, zipBefore: true);
                    },
                    child: const Text('Receive File'),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (isSplitting)
            Container(
              color: Colors.white54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      currentMessage,
                      style: const TextStyle(color: catppuccinText),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
