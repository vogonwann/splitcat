import 'dart:io' as io;
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:share_plus_dialog/share_plus_dialog.dart';
import 'logger.dart';

// Splits a file or zipped directory into smaller chunks.
Future<void> splitFile(String filePath,
    int chunkSize,
    BuildContext context,
    String selectedFileName,
    Function(bool) setIsSplitting,) async {
  if (chunkSize <= 0) {
    logger.e("Chunk size must be > 0.");
    return;
  }

  setIsSplitting(true);
  final chunkSizeInBytes = chunkSize * 1024 * 1024;
  final file = io.File(filePath);

  if (file
      .statSync()
      .type == io.FileSystemEntityType.file) {
    await _processAndSplitFile(
      file, chunkSizeInBytes, context, selectedFileName, setIsSplitting,
    );
  } else if (file
      .statSync()
      .type == io.FileSystemEntityType.directory) {
    final zipPath = await _zipDirectory(
        io.Directory(file.path), selectedFileName);
    final zipFile = io.File(zipPath);
    await _processAndSplitFile(
      zipFile, chunkSizeInBytes, context, selectedFileName, setIsSplitting,
    );
  }
}

// Zips a directory and returns the zip file path.
Future<String> _zipDirectory(io.Directory directory,
    String outputFileName) async {
  final tempDir = await getTemporaryDirectory();
  final outputZipPath = '${tempDir.path}/$outputFileName.zip';
  await zipFolder(directory.path, outputZipPath);
  logger.log(Level.info, 'File: $outputZipPath zipped successfully!');
  return outputZipPath;
}

// Processes the given file and splits it into chunks.
Future<void> _processAndSplitFile(io.File file,
    int chunkSizeInBytes,
    BuildContext context,
    String selectedFileName,
    Function(bool) setIsSplitting,) async {
  final bytes = await file.readAsBytes();
  final length = bytes.length;
  final nrOfChunks = (length / chunkSizeInBytes).ceil();
  List<io.File> chunkFiles = [];

  for (var i = 0; i < nrOfChunks; i++) {
    final start = i * chunkSizeInBytes;
    final end = (start + chunkSizeInBytes < length)
        ? start + chunkSizeInBytes
        : length;

    final chunkBytes = bytes.sublist(start, end);
    final chunkFileName = '${file.path}.part${(i + 1).toString().padLeft(
        2, '0')}';
    final chunkFile = io.File(chunkFileName);

    await chunkFile.writeAsBytes(chunkBytes);
    logger.d("Chunk saved: $chunkFileName");

    chunkFiles.add(chunkFile);
  }

  logger.log(Level.info, "File split into $nrOfChunks chunks.");

  if (context.mounted) {
    showCompletionDialog(
      context, "Splitting Finished",
      "File $selectedFileName split successfully.", null,
    );
  }
  // Offer the user the option to share the files.
  if (context.mounted && chunkFiles.isNotEmpty) {
    _offerFileSharing(chunkFiles, context);
  }
  setIsSplitting(false);
}

// Funkcija koja zipuje folder
Future<void> zipFolder(String sourceDirPath, String zipFilePath) async {
  final encoder = ZipEncoder();
  final archive = Archive();

  // Iteriraj kroz fajlove unutar foldera
  Directory sourceDir = Directory(sourceDirPath);
  List<FileSystemEntity> files = sourceDir.listSync(recursive: true);

  for (var file in files) {
    if (file is File) {
      String relativePath = file.path.substring(sourceDir.path.length + 1);
      List<int> bytes = await file.readAsBytes();
      archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
    }
  }

  // Kreiraj ZIP fajl
  File zipFile = File(zipFilePath);
  zipFile.writeAsBytesSync(encoder.encode(archive)!);
}

Future<String> getTempDirectory() async {
  Directory tempDir = await getTemporaryDirectory();
  return tempDir.path;
}

void mergeFiles(List<String> filePaths, BuildContext context,
    String? selectedFileName, Function(bool) setIsMergingState) async {
  if (filePaths.length > 1) {
    setIsMergingState(true);

    logger.log(Level.info, "Merging files: ${filePaths.join(', ')}");

    filePaths.sort();

    var splitFileName = filePaths.first.split('.');
    var mergedFile = io.File(
        "${splitFileName[0]}.${splitFileName[splitFileName.length == 2
            ? 1
            : splitFileName.length - 2]}");

    // Create stream for writing to file
    var output = mergedFile.openWrite();

    try {
      for (var filePath in filePaths) {
        // Read files in chunks and immediately write to the resulting file
        var input = io.File(filePath).openRead();
        await output.addStream(input);
      }

      if (context.mounted) {
        showCompletionDialog(context, "Merge Finished",
            "File $mergedFile merged successfully.", null);
      }
      logger.log(Level.info, "File $selectedFileName merged successfully");
    } catch (e) {
      logger.log(Level.error, "Error merging files: $e");
    } finally {
      await output.close();

      setIsMergingState(false);
    }
  } else {
    showCompletionDialog(
        context, "Merge Failed!", "You must select more then one file!", null);
  }
}

Future<PlatformFile> convertXFile(XFile file) async {
  return PlatformFile(
      name: file.name,
      size: await file.length(),
      path: file.path,
      bytes: await file.readAsBytes(),
      readStream: file.readAsBytes().asStream().map((i) => i));
}

void showCompletionDialog(BuildContext context, String title, String message,
    String? buttonText) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: Text(buttonText ?? "OK"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

// Offers the user the option to share the chunked files via other apps.
void _offerFileSharing(List<io.File> chunkFiles, BuildContext context) {
  final xFiles = chunkFiles.map((file) => XFile(file.path)).toList();

  if (io.Platform.isLinux) {
    ShareDialog.share(
      context,
      platforms: SharePlatform.defaults,
      body: 'Here are the split parts of the file.',
      subject: 'Split Files',
    );
  } else {
    Share.shareXFiles(xFiles, subject: "Split files", text: "Here are the split parts of the file");
  }

  logger.log(Level.info, "Sharing dialog opened.");
}

