import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:splitcat/pages/qr_code_read_screen.dart';
import 'package:splitcat/util/catppuccin.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;

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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                onChanged: (value) {
                  enteredPassword = value;
                },
              ),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                onChanged: (value) {
                  confirmPassword = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                setState(() {
                  password = confirmPassword;
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                if (enteredPassword == confirmPassword) {
                  setState(() {
                    password = enteredPassword;
                  });
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Passwords do not match!'),
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
    return Scaffold(
        appBar: AppBar(
          title: Text('Share via QR Code'),
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
                      child: const Text('Send File'),
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
                        const Text('Zip before',
                            style: TextStyle(color: catppuccinText)),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: showPasswordDialog,
                          child: const Text('Set Password'),
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
        ));
  }
}
