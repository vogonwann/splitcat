import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:splitcat/util/logger.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  Future<void> downloadFile(String url) async {
    setState(() {
      isDownloading = true;
    });

    final localizations = AppLocalizations.of(context);

    final request = http.Request('GET', Uri.parse(url));
    final response = await request.send();

    if (response.statusCode == 200) {
      // Чување стрима у бајтове
      final bytes = await response.stream.toBytes();

      // Сачувајте бајтове преко FilePicker-а
      final result = await FilePicker.platform.saveFile(
        dialogTitle: localizations!.qr_chooseLocationToSave,
        fileName: "splitcat_qr_${DateTime.now().microsecondsSinceEpoch}.zip",
        initialDirectory: '/storage/emulated/0/Download',
        bytes: bytes,  // Прослеђујемо бајтове овде
      );

      if (result != null) {
        logger.i("File downloaded and saved at $result");
      } else {
        logger.e("Save path selection was canceled.");
      }
    } else {
      logger.e("Error while downloading: ${response.statusCode}");
    }

    setState(() {
      isDownloading = false;
    });
  }


  Future<void> onQRViewCreated(QRViewController controller) async {
    qrViewController = controller;
    controller.scannedDataStream.listen((scanData) async {
      try {
        await downloadFile(scanData.code!);
      } catch (e) {
        logger.e("Error while downloading file: $e");
        showErrorSnackbar("Error while downloading file: $e");
      }
    });
  }

  void showErrorSnackbar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localization!.qr_shareViaQrCode),
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
                Text(localization.qr_transferInProgress),
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
                Text(localization.qr_scanTheQRCodeToDownloadFile),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
