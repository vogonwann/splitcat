import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:splitcat/util/catppuccin.dart';

import '../util/logger.dart';

class MergeScreen extends StatefulWidget {
  const MergeScreen({super.key});

  @override
  _MergeScreenState createState() => _MergeScreenState();
}

class _MergeScreenState extends State<MergeScreen> {
  String? selectedFileName;
  IconData? selectedFileIcon;
  bool isMerging = false;
  List<PlatformFile>? selectedFiles = List.empty();

  void mergeFiles(List<String> filePaths) async {
    if (filePaths.length > 1) {
      setState(() {
        isMerging = true;
      });

      logger.log(Level.info, "Merging files: ${filePaths.join(', ')}");

      // Сортирај путање до фајлова
      filePaths.sort();

      // Генериши име за резултујући фајл
      var splitedFileName = filePaths.first.split('.');
      var mergedFile = File(
          "${splitedFileName[0]}.${splitedFileName[splitedFileName.length == 2 ? 1 : splitedFileName.length - 2]}");

      // Креирај стрим за упис у фајл
      var output = mergedFile.openWrite();

      try {
        for (var filePath in filePaths) {
          // Читај фајлове у деловима и одмах уписуј у резултујући фајл
          var input = File(filePath).openRead();
          await output.addStream(input);
        }
      } catch (e) {
        logger.log(Level.error, "Error merging files: $e");
      } finally {
        await output.close();
        setState(() {
          isMerging = false;
        });
      }
    } else {
      // If only first file is selected
      final firstFileExtension =
          filePaths[0].split('.')[filePaths[0].split('.').length - 1];
      if (firstFileExtension == 'part01') {
        var file = File(filePaths[0]);
        final dir = file.parent;
        final splitedPath = file.path.split('/');
        final fileNameWithExtension = splitedPath[splitedPath.length - 1];
        final prefix = fileNameWithExtension.split('.')[0];

        if (!dir.existsSync()) {
          logger.e('Directory does not exist');
          return;
        }

        var splitedFileName = filePaths.first.split('.');
        var mergedFile = File(
            "${splitedFileName[0]}.${splitedFileName[splitedFileName.length == 2 ? 1 : splitedFileName.length - 2]}");

        // Креирај стрим за упис у фајл
        var output = mergedFile.openWrite();

        // Листај све фајлове у директоријуму и филтрирај оне који почињу са `prefix`
        final files = dir.listSync().where((entity) {
          return entity is File &&
              entity.path.split('/').last.startsWith(prefix);
        });
        try {
          for (var file in files) {
            // Читај фајлове у деловима и одмах уписуј у резултујући фајл
            var input = File(file.path).openRead();
            await output.addStream(input);
          }

          showCompletionDialog(
              context, "File $selectedFileName merged successfully.");
        } catch (e) {
          logger.log(Level.error, "Error merging files: $e");
          showCompletionDialog(
              context, "File $selectedFileName merging failed.");
        } finally {
          await output.close();
          setState(() {
            isMerging = false;
          });
        }
      } else {
        logger.log(Level.error, "Wrong file selected: $filePaths[0]");
        showCompletionDialog(context, "File $selectedFileName merging failed.");
        throw Exception("Please select first or all files.");
      }
    }
  }

  void showCompletionDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Merge finished"),
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
    if (isMerging) {
      return const Center(
          child: SimpleDialog(
        elevation: 0.0,
        backgroundColor:
            catppuccinBackground, // can change this to your prefered color
        children: <Widget>[
          Center(
            child: CircularProgressIndicator(),
          )
        ],
      ) // Prikaz indikatora
          );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Please select first or all files to merge."),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 20), // Veće dugme
              ),
              onPressed: () async {
                FilePickerResult? result;
                if (Platform.isLinux) {
                  result =
                      await FilePickerLinux().pickFiles(allowMultiple: true);
                } else {
                  result =
                      await FilePicker.platform.pickFiles(allowMultiple: true);
                }
                if (result != null) {
                  setState(() {
                    selectedFileName =
                        result?.files.first.name.split('.').removeAt(0);
                    selectedFileIcon = Icons.insert_drive_file; // Primer ikone
                    selectedFiles = result?.files;
                  });
                }
              },
              child: const Text('Browse Files'),
            ),
            if (selectedFileName != null) ...[
              ListTile(
                leading: Icon(selectedFileIcon),
                title: Text(selectedFileName!),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 20), // Veće dugme
              ),
              onPressed: selectedFileName != null
                  ? () {
                    if (selectedFiles != null) {
                      mergeFiles(
                          selectedFiles!.map((file) => file.path!).toList());
                    }
                  }
                  : null, // Disabled ako fajl nije odabran
              child: const Text('Merge Files'),
            ),
          ],
        ),
      );
    }
  }
}