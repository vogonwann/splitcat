import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:splitcat/util/catppuccin.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../util/split_merge.dart';

class MultipleScreen extends StatefulWidget {
  const MultipleScreen({super.key});

  @override
  _MultipleScreenState createState() => _MultipleScreenState();
}

class _MultipleScreenState extends State<MultipleScreen> {
  String? selectedFileName;
  String? selectedFilePath;
  IconData? selectedFileIcon;
  bool isSplitting = false;
  bool zipBefore = false;
  final TextEditingController _sizeController = TextEditingController();
  String currentMessage = '';
  String? password;
  FilePickerResult selectedFiles = FilePickerResult([]);

  //late List<file_selector.XFile> selectedFiles = List.empty(growable: true);

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
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 24,),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 20), // Veće dugme
                  ),
                  onPressed: () async {
                    var result = await FilePicker.platform
                        .pickFiles(allowMultiple: true);
                    if (result != null) {
                      setState(() {
                        selectedFiles = result;
                        selectedFileIcon = Icons.insert_drive_file;
                      });
                    }
                  },
                  child: Text(localizations!.global_browseFiles)),
              if (selectedFiles != null) ...[
                Expanded(
                    child: ListView.builder(
                        itemCount: selectedFiles.files.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: Icon(selectedFileIcon),
                            title: Text(selectedFiles.files[index].name),
                          );
                        }))
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
                onPressed: selectedFiles.files.isNotEmpty &&
                        _sizeController.text.isNotEmpty
                    ? () {
                        int chunkSize = int.tryParse(_sizeController.text) ?? 0;
                        splitFiles2(selectedFiles, chunkSize, context,
                            ((splitting) {
                          setState(() {
                            isSplitting = splitting;
                          });
                        }), ((message) {
                          setState(() {
                            currentMessage = message;
                          });
                        }), zipBefore: true, password: password);
                      }
                    : null,
                // Disable ako fajl nije odabran ili chunk size nije unet
                child: Text(localizations.global_splitFiles),
              ),
              SizedBox(height: 24,)
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
