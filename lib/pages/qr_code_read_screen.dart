import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:splitcat/util/logger.dart';

class QrCodeReadScreen extends StatefulWidget {
  const QrCodeReadScreen({super.key});

  @override
  _QrCodeReadScreenState createState() => _QrCodeReadScreenState();
}

class _QrCodeReadScreenState extends State<QrCodeReadScreen> {
  bool isDownloading = false; // Indikator preuzimanja
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? qrViewController;

  @override
  void dispose() {
    qrViewController?.dispose();
    super.dispose();
  }

  Future<void> downloadFile(String url, String savePath) async {
    setState(() {
      isDownloading = true;
    });

    logger.d("Download file: savePath: $savePath");

    final request = http.Request('GET', Uri.parse(url));
    final response = await request.send();

    if (response.statusCode == 200) {
      final file = File(savePath);

      await response.stream.pipe(file.openWrite());
      logger.i("File downloaded and saved at $savePath");


    } else {
      logger.e("Error while downloading: ${response.statusCode}");
    }

    setState(() {
      isDownloading = false;
    });
  }

  void onQRViewCreated(QRViewController controller) {
    qrViewController = controller;
    controller.scannedDataStream.listen((scanData) async {
      // Choose file save location when QR code is scanned
      String? savePath = await FilePicker.platform.saveFile(dialogTitle: "Choose location to save", fileName: "splitcat_qr_${DateTime.now().microsecondsSinceEpoch}"); // Zamenite sa pravim putem

      await downloadFile(scanData.code!, savePath!);
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
                CircularProgressIndicator(), // Indefinite spinner
                SizedBox(height: 12),
                Text('Transfer in progress...'),
              ],
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: QRView(
                    key: qrKey,
                    onQRViewCreated: onQRViewCreated,
                  ),
                ),
                SizedBox(height: 24),
                Text('Scan the QR code to download a file'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
