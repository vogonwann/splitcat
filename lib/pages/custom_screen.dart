import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:splitcat/util/logger.dart';
import 'package:file_selector/file_selector.dart' as file_selector;

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

  // Stub funkcija za splitovanje
  void splitFile(String filePath, int chunkSize) async {
    // Pretvori chunkSize u bajtove (MB * 1024 * 1024)
    int chunkSizeInBytes = chunkSize * 1024 * 1024;

    if (chunkSize <= 0) {
      logger.e("Chunk size mora biti veći od 0.");
      return;
    }

    var file = File(filePath);
    var bytes = await file.readAsBytes(); // Čita sve bajtove iz fajla
    var length = bytes.length; // Ukupna dužina fajla u bajtovima
    var nrOfChunks = (length / chunkSizeInBytes).ceil(); // Ukupan broj chunkova

    for (var i = 0; i < nrOfChunks; i++) {
      // Početni indeks trenutnog chunk-a
      int start = i * chunkSizeInBytes;

      // Završni indeks trenutnog chunk-a (moramo paziti da ne pređe ukupnu dužinu fajla)
      int end = (start + chunkSizeInBytes < length)
          ? start + chunkSizeInBytes
          : length;

      // Izvuci trenutni chunk
      Uint8List chunkBytes = bytes.sublist(start, end);

      // Kreiraj novi fajl za svaki chunk (imeFajla.i)
      String chunkFileName =
          '$filePath.part${(i + 1) < 10 ? "0${i + 1}" : i + 1}';
      var chunkFile = File(chunkFileName);

      // Snimi chunk u fajl
      await chunkFile.writeAsBytes(chunkBytes);

      logger.d("Sačuvan chunk $chunkFileName");
    }

    logger.log(Level.info, "Fajl je uspešno podeljen u $nrOfChunks chunk-ova.");
    showCompletionDialog(
        context, "File $selectedFileName splited successfully.");
  }

  void showCompletionDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Split finished"),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Затвори дијалог
              },
            ),
          ],
        );
      },
    );
  }

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
                    splitFile(selectedFilePath!, chunkSize);
                  }
                : null, // Disable ako fajl nije odabran ili chunk size nije unet
            child: const Text('Split File'),
          ),
        ],
      ),
    );
  }
}
