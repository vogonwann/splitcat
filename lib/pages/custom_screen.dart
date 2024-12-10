import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:splitcat/util/catppuccin.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../util/split_merge.dart';

class CustomSplitScreen extends StatefulWidget {
  const CustomSplitScreen({super.key});

  @override
  _CustomSplitScreenState createState() => _CustomSplitScreenState();
}

class _CustomSplitScreenState extends State<CustomSplitScreen> {
  String? selectedFileName;
  String? selectedFilePath;
  IconData? selectedFileIcon;
  bool isSplitting = false;
  bool zipBefore = false;
  final TextEditingController _sizeController = TextEditingController();
  String currentMessage = '';
  String? password;

  @override
  void initState() {
    super.initState();
    // Dodavanje listenera za ažuriranje stanja kada se promeni veličina
    _sizeController.addListener(() {
      setState(() {});
    });
  }

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
                decoration: InputDecoration(labelText: localizations.global_password),
                onChanged: (value) {
                  enteredPassword = value;
                },
              ),
              TextField(
                obscureText: true,
                decoration:
                    InputDecoration(labelText: localizations.global_confirmPassword),
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
              child: const Text('OK'),
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
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 20), // Veće dugme
                ),
                onPressed: () async {
                  if (Platform.isAndroid || Platform.isIOS) {
                    FilePickerResult? result =
                        await FilePicker.platform.pickFiles();
                    if (result != null) {
                      setState(() {
                        selectedFilePath = result.files.single.path;
                        selectedFileName = result.files.single.name;
                        selectedFileIcon =
                            Icons.insert_drive_file; // Primer ikone
                      });
                    }
                  } else {
                    var result = await file_selector.openFile();
                    if (result != null) {
                      setState(() {
                        selectedFilePath = result.path;
                        selectedFileName = result.name;
                        selectedFileIcon = Icons.insert_drive_file;
                      });
                    }
                  }
                },
                child: Text(localizations!.global_browseFile),
              ),
              if (selectedFileName != null) ...[
                ListTile(
                  leading: Icon(selectedFileIcon),
                  title: Text(selectedFileName!),
                ),
              ],
              Padding(
                padding: const EdgeInsets.all(24),
                child: TextField(
                  controller: _sizeController,
                  decoration: InputDecoration(
                    labelText: localizations.global_enterChunkSizeInMb,
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Switch(
                    value: zipBefore,
                    onChanged: (bool value) {
                      setState(() {
                        zipBefore = value;
                      });
                    },
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
                height: 12,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                ),
                onPressed: selectedFileName != null &&
                        _sizeController.text.isNotEmpty
                    ? () {
                        int chunkSize = int.tryParse(_sizeController.text) ?? 0;
                        splitFile(selectedFilePath!, chunkSize, context,
                            selectedFileName!, ((splitting) {
                          setState(() {
                            isSplitting = splitting;
                          });
                        }), ((message) {
                          setState(() {
                            currentMessage = message;
                          });
                        }), zipBefore: zipBefore, password: password);
                      }
                    : null,
                // Disable ako fajl nije odabran ili chunk size nije unet
                child: Text(localizations.global_splitFile),
              ),
            ],
          ),
        ),
        if (isSplitting)
          Container(
            color: Colors.white54,
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(
                    height: 12,
                  ),
                  Text(
                    currentMessage,
                    style: const TextStyle(color: catppuccinText),
                  )
                ],
              ),
            ),
          ),
      ],
    );
  }
}
