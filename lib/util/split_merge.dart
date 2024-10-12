import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'logger.dart';

void splitFile(String filePath, int chunkSize, BuildContext context, String selectedFileName, Function(bool) setIsSplitting) async {
  // Pretvori chunkSize u bajtove (MB * 1024 * 1024)
  setIsSplitting(true);
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

  if (context.mounted) {
    showCompletionDialog(
        context,
        "Splitting Finished",
        "File $selectedFileName splited successfully.",
        null);
  }

  setIsSplitting(false);
}

void mergeFiles(List<String> filePaths, BuildContext context, String? selectedFileName, Function(bool) setIsMergingState) async {
  if (filePaths.length > 1) {
    setIsMergingState(true);

    logger.log(Level.info, "Merging files: ${filePaths.join(', ')}");

    filePaths.sort();

    var splitFileName = filePaths.first.split('.');
    var mergedFile = File(
        "${splitFileName[0]}.${splitFileName[splitFileName.length == 2 ? 1 : splitFileName.length - 2]}");

    // Create stream for writing to file
    var output = mergedFile.openWrite();

    try {
      for (var filePath in filePaths) {
        // Read files in chunks and immediately write to the resulting file
        var input = File(filePath).openRead();
        await output.addStream(input);
      }

      if (context.mounted) {
        showCompletionDialog(
            context,
            "Merge Finished",
            "File $mergedFile merged successfully.",
            null);
      }
    } catch (e) {
      logger.log(Level.error, "Error merging files: $e");
    } finally {
      await output.close();

      setIsMergingState(false);
    }
  } else {
    showCompletionDialog(
        context,
        "Merge Failed!",
        "You must select more then one file!",
        null
    );
    // // If only first file is selected
    // final firstFileExtension =
    //   filePaths[0].split('.')[filePaths[0].split('.').length - 1];
    // if (firstFileExtension == 'part01') {
    //   var file = File(filePaths[0]);
    //   final dir = file.parent;
    //   final splitedPath = file.path.split('/');
    //   final fileNameWithExtension = splitedPath[splitedPath.length - 1];
    //   final prefix = fileNameWithExtension.split('.')[0];
    //
    //   if (!dir.existsSync()) {
    //     logger.e('Directory does not exist');
    //     return;
    //   }
    //
    //   var splitFileName = filePaths.first.split('.');
    //   var mergedFile = File(
    //       "${splitFileName[0]}.${splitFileName[splitFileName.length == 2 ? 1 : splitFileName.length - 2]}");
    //
    //   var output = mergedFile.openWrite();
    //
    //   final files = dir.listSync();
    //   // files.sort();
    //   try {
    //     var fileList = [];
    //     for (var file in files) {
    //       if (file is File && file.path.split('/').last.startsWith(prefix)) {
    //         var input = File(file.path).openRead();
    //         fileList.add(input);
    //       }
    //     }
    //
    //     // TODO: merge files sorted
    //
    //     if (context.mounted) {
    //       showCompletionDialog(
    //           context, "File $selectedFileName merged successfully.");
    //     }
    //   } catch (e) {
    //     logger.log(Level.error, "Error merging files: $e");
    //
    //     if (context.mounted) {
    //       showCompletionDialog(
    //           context, "File $selectedFileName merging failed.");
    //     }
    //   } finally {
    //     await output.close();
    //     setIsMergingState(false);
    //   }
    // } else {
    //   logger.log(Level.error, "Wrong file selected: $filePaths[0]");
    //   showCompletionDialog(context, "File $selectedFileName merging failed.");
    //   throw Exception("Please select first or all files.");
    // }
  }
}

Future<PlatformFile> convertXFile(XFile file) async {
  return PlatformFile(
    name: file.name,
    size: await file.length(),
    path: file.path,
    bytes: await file.readAsBytes(),
    readStream: file.readAsBytes().asStream().map((i) => i)
  );
}

void showCompletionDialog(BuildContext context, String title, String message, String? buttonText) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title:  Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child:  Text(buttonText ?? "OK"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
