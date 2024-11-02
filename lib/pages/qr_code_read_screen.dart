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
  bool isDownloading = false; // Indikator preuzimanja
  double downloadProgress = 0.0; // Procenat preuzimanja
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

  void onQRViewCreated(QRViewController controller) {
    qrViewController = controller;
    controller.scannedDataStream.listen((scanData) async {
      // Kada se QR kod skenira, preuzmi fajl
      String savePath = "/path/to/save/file.zip"; // Zamenite sa pravim putem

      downloadFile(scanData.code!, savePath); // Zamenite sa pravim putem
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
                Text('Skenirajte QR kod za preuzimanje fajla'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}