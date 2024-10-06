import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:splitcat/util/catppuccin.dart';
import 'package:splitcat/util/logger.dart';
class PresetScreen extends StatefulWidget {
  const PresetScreen({super.key});

  @override
  _PresetScreenState createState() => _PresetScreenState();
}
class _PresetScreenState extends State<PresetScreen> {
  String? selectedFileName;
  String? selectedFilePath;
  String? selectedApplicationName;
  IconData? selectedFileIcon;
  bool isSplitting = false;
  bool isFinished = false;

  final List<Map<String, dynamic>> appLimits = [
    {'App': 'Telegram', 'Limit': 2048, 'Icon': Icons.message}, // 2GB
    {'App': 'Discord', 'Limit': 25, 'Icon': Icons.discord}, // 25MB
    {'App': 'WhatsApp', 'Limit': 2048, 'Icon': Icons.chat}, // 2GB
    {'App': 'Viber', 'Limit': 200, 'Icon': Icons.phone}, // 200MB
    {'App': 'Skype', 'Limit': 300, 'Icon': Icons.video_call}, // 300MB
    {'App': 'Teams', 'Limit': 250, 'Icon': Icons.group}, // 250MB
    {'App': 'Mail', 'Limit': 25, 'Icon': Icons.mail}, // 250MB
  ];

  void splitFile(String filePath, int chunkSize) async {
    if (chunkSize <= 0) {
      logger.e("Chunk size mora biti veći od 0.");
      return;
    }

    setState(() {
      isSplitting = true;
      isFinished = false;
    });

    int chunkSizeInBytes = chunkSize * 1024 * 1024;
    var file = File(filePath);
    var bytes = await file.readAsBytes();
    var length = bytes.length;
    var nrOfChunks = (length / chunkSizeInBytes).ceil();

    for (var i = 0; i < nrOfChunks; i++) {
      int start = i * chunkSizeInBytes;
      int end = (start + chunkSizeInBytes < length)
          ? start + chunkSizeInBytes
          : length;
      Uint8List chunkBytes = bytes.sublist(start, end);
      String chunkFileName =
          '$filePath.part${(i + 1) < 10 ? "0${i + 1}" : i + 1}';
      var chunkFile = File(chunkFileName);
      await chunkFile.writeAsBytes(chunkBytes);
      logger.i("Sačuvan chunk $chunkFileName");
    }

    logger.i("Fajl je uspešno podeljen u $nrOfChunks chunk-ova.");

    setState(() {
      isSplitting = false; // Postavi na false kada završi
      isFinished = true;
    });

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

  IconData getIconForFileType(String? filePath) {
    String extension = filePath!.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mkv':
        return Icons.movie;
      case 'mp3':
      case 'wav':
        return Icons.music_note;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isSplitting) ...[
          const SimpleDialog(
            elevation: 0.0,
            backgroundColor:
                catppuccinBackground, // can change this to your prefered color
            children: <Widget>[
              Center(
                child: CircularProgressIndicator(),
              )
            ],
          ), // Prikaz indikatora
        ] else
          Expanded(
            child: ListView.builder(
              itemCount: appLimits.length,
              itemBuilder: (context, index) {
                return Card(
                  color: catppuccinSurface,
                  child: ListTile(
                    leading:
                        Icon(appLimits[index]['Icon'], color: catppuccinAccent),
                    title: Text(
                      appLimits[index]['App'],
                      style: const TextStyle(color: catppuccinText),
                    ),
                    subtitle: Text(
                      'Limit: ${appLimits[index]['Limit']} MB',
                      style: TextStyle(color: catppuccinText.withOpacity(0.7)),
                    ),
                    onTap: () async {
                      if (Platform.isAndroid || Platform.isIOS) {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles();
                        if (result != null) {
                          setState(() {
                            selectedApplicationName = appLimits[index]['App'];
                            selectedFilePath = result.files.single.path;
                            selectedFileName = result.files.single.name;
                            selectedFileIcon =
                                getIconForFileType(result.files.single.path!);
                          });
                        }
                      } else {
                        var result = await openFile();
                        setState(() {
                          selectedApplicationName = appLimits[index]['App'];
                          selectedFilePath = result?.path;
                          selectedFileName = result?.name;
                          selectedFileIcon =
                              getIconForFileType(result?.path);
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
        if (selectedFileName != null) ...[
          if (!isSplitting) ...{
            if (!isFinished)
              ListTile(
                leading: Icon(selectedFileIcon, color: catppuccinPrimary),
                title: Text(
                  selectedFileName!,
                  style: const TextStyle(color: catppuccinText),
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    var matchedApp = appLimits.firstWhere(
                      (element) =>
                          selectedApplicationName!.contains(element['App']),
                      orElse: () => {'App': '', 'Limit': 0},
                    );

                    logger.i("Odabran fajl: $selectedFileName");
                    logger.i("Poklapanje: $matchedApp");

                    if (matchedApp['Limit'] > 0) {
                      int limit = matchedApp['Limit'];
                      splitFile(selectedFilePath!, limit);
                      logger.i(
                          "Pokrenut split fajla: $selectedFileName sa limitom $limit MB");
                    } else {
                      logger.e(
                          "Nema poklapanja sa unapred definisanim aplikacijama.");
                    }
                  },
                  child: const Text('Split'),
                ),
              )
          } else
            Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ListTile(
                    leading: Icon(selectedFileIcon, color: catppuccinPrimary),
                    title: Text(
                      selectedFileName!,
                      style: const TextStyle(color: catppuccinText),
                    ),
                  ),
                ])
        ],
      ],
    );
  }
}