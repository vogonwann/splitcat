import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:splitcat/util/logger.dart';
import 'package:file_selector/file_selector.dart' as file_selector;

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
  final TextEditingController _sizeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Center(
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
                FilePickerResult? result = await FilePicker.platform
                    .pickFiles();
                if (result != null) {
                  setState(() {
                    selectedFilePath = result.files.single.path;
                    selectedFileName = result.files.single.name;
                    selectedFileIcon = Icons.insert_drive_file; // Primer ikone
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            ),
            onPressed: selectedFileName != null &&
                    _sizeController.text.isNotEmpty
                ? () {
                    int chunkSize = int.tryParse(_sizeController.text) ?? 0;
                     splitFile(
                        selectedFilePath!,
                        chunkSize,
                        context,
                        selectedFileName!,
                        ((isSplitting) {
                          setState(() {
                            isSplitting = isSplitting;
                          });
                        })
                    );
                  }
                : null, // Disable ako fajl nije odabran ili chunk size nije unet
            child: const Text('Split File'),
          ),
        ],
      ),
    );
  }
}
