import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:splitcat/pages/qr_code_read_screen.dart';
import 'package:splitcat/util/catppuccin.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../util/logger.dart';
import '../util/split_merge.dart';

class QrCodeScreen extends StatefulWidget {
  const QrCodeScreen({super.key});

  @override
  _QrCodeScreenState createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends State<QrCodeScreen> {
  String? selectedFileName;
  String? selectedFilePath;
  IconData? selectedFileIcon;
  bool isSplitting = false;
  bool zipBefore = false;
  final TextEditingController _sizeController = TextEditingController();
  String currentMessage = '';
  FilePickerResult selectedFile = FilePickerResult([]);
  String qrCodeData = 'https://splitcat.janjic.lol';
  String? password;

  @override
  void dispose() {
    _sizeController.dispose();
    super.dispose();
  }
  void showPasswordDialog() {
    String enteredPassword = '';
    String confirmPassword = '';
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations!.global_enterPassword),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                obscureText: true,
                decoration: InputDecoration(labelText: localizations.global_enterPassword),
                onChanged: (value) {
                  enteredPassword = value;
                },
              ),
              TextField(
                obscureText: true,
                decoration: InputDecoration(labelText: localizations.global_confirmPassword),
                onChanged: (value) {
                  confirmPassword = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(localizations.global_cancel),
              onPressed: () {
                setState(() {
                  password = confirmPassword;
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(localizations.global_ok),
              onPressed: () {
                if (enteredPassword == confirmPassword) {
                  setState(() {
                    password = enteredPassword;
                  });
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localizations.global_passwordsDoNotMatch),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

    @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
        appBar: AppBar(
          title: Text(localizations!.qr_shareViaQrCode),
        ),
        body: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 20),
                      ),
                      onPressed: () async {
                        var result = await FilePicker.platform
                            .pickFiles(allowMultiple: false);
                        if (result != null) {
                          setState(() {
                            selectedFile = result;
                            selectedFileIcon = Icons.insert_drive_file;
                          });
                          shareFiles(selectedFile, context, (splitting) {
                            setState(() {
                              isSplitting = splitting;
                            });
                          }, (qrCode) {
                            setState(() {
                              qrCodeData = qrCode;
                            });
                          }, zipBefore: zipBefore);
                        }
                      },
                      child: Text(localizations.global_sendFile),
                    ),
                    SizedBox(height: 24,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Switch(
                          value: true,
                          onChanged: null,
                         // onChanged: (bool value) {
                         //   setState(() {
                         //     zipBefore = value;
                         //   });
                         // },
                        ),
                        Text(localizations.global_zipBefore,
                            style: TextStyle(color: catppuccinText)),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: showPasswordDialog,
                          child: Text(localizations.global_setPassword),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 24,
                    ),
                    QrImageView(
                      data: qrCodeData,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    if (selectedFile.files.isNotEmpty)
                      ListTile(
                        leading: Icon(selectedFileIcon),
                        title: Text(selectedFile.files.first.name),
                      ),
                    SizedBox(height: 12),
                    if (Platform.isAndroid || Platform.isIOS)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 20),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => QrCodeReadScreen()),
                          );
                        },
                        child: Text(localizations.qr_receiveFile),
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
        ));
  }
}
