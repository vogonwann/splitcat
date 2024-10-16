import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'logger.dart';

void splitFile(String filePath, int chunkSize, BuildContext context, String selectedFileName, Function(bool) setIsSplitting) async {
  //  Transform chunks to bytes (MB * 1024 * 1024)
  setIsSplitting(true);
  int chunkSizeInBytes = chunkSize * 1024 * 1024;

  if (chunkSize <= 0) {
    logger.e("Chunk size must be > 0.");
    return;
  }

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

    logger.d("Chunk saved $chunkFileName");
  }

  logger.log(Level.info, "File splited successfully into $nrOfChunks chunks.");

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
      logger.log(Level.info, "File ${selectedFileName} merged successfully");
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
