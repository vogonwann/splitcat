import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:splitcat/util/catppuccin.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../util/split_merge.dart';

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
  String currentMessage = '';

  void showCompletionDialog(BuildContext context, String message) {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations!.merge_mergeFinished),
          content: Text(message),
          actions: [
            TextButton(
              child: Text(localizations.global_ok),
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
    final localization = AppLocalizations.of(context);
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
      ));
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(localization!.merge_pleaseSelectFilesToMerge),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 20), // Veće dugme
              ),
              onPressed: () async {
                if (Platform.isAndroid || Platform.isIOS) {
                  setState(() {
                    isMerging = true;
                    currentMessage = localization.merge_loadingFilesToMerge;
                  });
                  var result =
                      await FilePicker.platform.pickFiles(allowMultiple: true);
                  setState(() {
                    selectedFileName =
                        _getFileNameWithoutExtension(result!.files.first.name);
                    //result?.files.first.name.split('.').removeAt(0);
                    selectedFileIcon = Icons.insert_drive_file;
                    selectedFiles = result?.files;
                    isMerging = false;
                  });
                } else {
                  var result = await openFiles();
                  var files = await Future.wait<PlatformFile>(
                      result.map((file) async => await convertXFile(file)));
                  setState(() {
                    selectedFileName =
                        _getFileNameWithoutExtension(result.first.name);
                    selectedFileIcon = Icons.insert_drive_file;
                    selectedFiles = files;
                  });
                }
              },
              child: Text(localization.global_browseFiles),
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
                            selectedFiles!.map((file) => file.path!).toList(),
                            context,
                            selectedFileName, ((merging) {
                          setState(() {
                            isMerging = merging;
                          });
                        }), ((message) {
                          setState(() {
                            currentMessage = message;
                          });
                        }));
                      }
                    }
                  : null, // Disabled ako fajl nije odabran
              child: Text(localization.merge_mergeFiles),
            ),
          ],
        ),
      );
    }
  }

  String _getFileNameWithoutExtension(String name) {
    String baseName = basename(name);
    int lastDotIndex = baseName.lastIndexOf('.');

    return lastDotIndex != -1 ? baseName.substring(0, lastDotIndex) : name;
  }
}
