import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:splitcat/util/catppuccin.dart';

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

  @override
  Widget build(BuildContext context) {
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
                child: const Text('Browse File'),
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
                  decoration: const InputDecoration(
                    labelText: 'Enter chunk size in MB',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: zipBefore,
                    onChanged: (bool? value) {
                      setState(() {
                        zipBefore = value!;
                      });
                    },
                  ),
                  const Text('Zip before',
                      style: TextStyle(color: catppuccinText)),
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
                        }), zipBefore: zipBefore);
                      }
                    : null,
                // Disable ako fajl nije odabran ili chunk size nije unet
                child: const Text('Split File'),
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
