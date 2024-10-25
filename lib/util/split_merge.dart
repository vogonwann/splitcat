import 'dart:io' as io;
import 'dart:io';
import 'dart:typed_data';

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

import 'package:archive/archive.dart';
import 'package:flutter_archive/flutter_archive.dart' as farchive;

import 'package:path/path.dart' as path;

/// Zips the given directory and returns the path to the zip file.
Future<String> _zipDirectory(
    io.Directory directory, String outputFileName) async {
  final archive = Archive();

  // Traverse all files in the directory and add them to the archive.
  await for (var entity
      in directory.list(recursive: true, followLinks: false)) {
    if (entity is io.File) {
      final fileBytes = await entity.readAsBytes();
      final relativePath = path.relative(entity.path, from: directory.path);
      archive.addFile(ArchiveFile(relativePath, fileBytes.length, fileBytes));
    }
  }

  // Save the ZIP archive to a temporary file.
  final zipEncoder = ZipEncoder();
  final zipPath = path.join(directory.parent.path, '$outputFileName.zip');
  final zipFile = io.File(zipPath);
  await zipFile.writeAsBytes(zipEncoder.encode(archive)!);

  return zipPath;
}

/// Splits a file or zipped directory into smaller chunks, with optional encryption.
Future<void> splitFile(
  String filePath,
  int chunkSize,
  BuildContext context,
  String selectedFileName,
  Function(bool) setIsSplitting,
  Function(String) setCurrentMessage, {
  bool zipBefore = false,
  bool encryptBefore = false,
  String? password,
}) async {
  if (chunkSize <= 0) {
    logger.e("Chunk size must be > 0.");
    return;
  }

  setIsSplitting(true); // Start splitting process
  setCurrentMessage("Starting to split file $selectedFileName");
  final chunkSizeInBytes = chunkSize * 1024 * 1024;
  // var file = io.File(filePath);
  io.File file = io.File(filePath);

  if (zipBefore) {
    logger.i("Creating archive $filePath.zip");
    setCurrentMessage("Creating archive $filePath.zip");
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
    
      final archive = Archive();
      final archiveFile = ArchiveFile(path.basename(filePath), bytes.length, bytes);
      archive.addFile(archiveFile);
      final archiveEncoded = ZipEncoder().encode(archive);
      if (archiveEncoded == null) return;

      final zipFile = await File("$filePath.zip").writeAsBytes(archiveEncoded);

      await _processAndSplitFile(zipFile, chunkSizeInBytes, context,
          selectedFileName, setIsSplitting, setCurrentMessage, isZip: true);

      logger.i("Archive $filePath.zip created");
      setCurrentMessage("Archive $filePath.zip created");
    } catch (e) {
      logger.e("$e");
    }
  } else {
    // Split the (possibly encrypted) file into chunks.
    await _processAndSplitFile(file, chunkSizeInBytes, context,
        selectedFileName, setIsSplitting, setCurrentMessage);
  }
}

// Processes the given file and splits it into chunks.
Future<void> _processAndSplitFile(
    io.File file,
    int chunkSizeInBytes,
    BuildContext context,
    String selectedFileName,
    Function(bool) setIsSplitting,
    Function(String) setCurrentMessage,
    { bool isZip = false }) async {
  final bytes = await file.readAsBytes();
  final length = bytes.length;
  final nrOfChunks = (length / chunkSizeInBytes).ceil();
  List<io.File> chunkFiles = [];

  for (var i = 0; i < nrOfChunks; i++) {
    final start = i * chunkSizeInBytes;
    final end =
        (start + chunkSizeInBytes < length) ? start + chunkSizeInBytes : length;

    final chunkBytes = bytes.sublist(start, end);
    final chunkFileName =
        '${file.path}.part${(i + 1).toString().padLeft(2, '0')}';
    final chunkFile = io.File(chunkFileName);

    await chunkFile.writeAsBytes(chunkBytes);
    logger.d("Chunk saved: $chunkFileName");
    setCurrentMessage("Chunk saved: $chunkFileName");

    chunkFiles.add(chunkFile);
    if (isZip) {
      _deleteFile(file);
    }
  }

  logger.log(Level.info, "File split into $nrOfChunks chunks.");
  setCurrentMessage("File split into $nrOfChunks chunks.");

  if (context.mounted) {
    showCompletionDialog(
      context,
      "Splitting Finished",
      "File $selectedFileName split successfully.",
      null,
    );
  }
  // Offer the user the option to share the files.
  if (context.mounted && chunkFiles.isNotEmpty) {
    _offerFileSharing(chunkFiles, context);
  }
  setIsSplitting(false);
}

Future<void> _deleteFile(io.File file) async {
  try {
    if (await file.exists()) {
      await file.delete();
    } else {
      logger.log(Level.warning, "File doesn't exist: ${path.basename(file.path)}");
    }
  } catch(e) {
    logger.log(Level.error, "$e");
  }
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

void mergeFiles(
    List<String> filePaths,
    BuildContext context,
    String? selectedFileName,
    Function(bool) setIsMergingState,
    Function(String) setCurrentMessage) async {
  if (filePaths.length > 1) {
    setIsMergingState(true);

    logger.log(Level.info, "Merging files: ${filePaths.join(', ')}");
    setCurrentMessage("Merging files: ${filePaths.join(', ')}");

    filePaths.sort();

    var splitFileName = filePaths.first.split('.');
    var mergedFile = io.File(
        "${splitFileName[0]}.${splitFileName[splitFileName.length == 2 ? 1 : splitFileName.length - 2]}");

    // Create stream for writing to file
    var output = mergedFile.openWrite();

    try {
      for (var filePath in filePaths) {
        // Read files in chunks and immediately write to the resulting file
        var input = io.File(filePath).openRead();
        await output.addStream(input);
        logger.log(Level.info, "File $filePath merged");
        setCurrentMessage("File $filePath merged");
      }

      if (context.mounted) {
        showCompletionDialog(context, "Merge Finished",
            "File $mergedFile merged successfully.", null);
      }
      logger.log(Level.info, "File $selectedFileName merged successfully");
      setCurrentMessage("File $selectedFileName merged successfully");
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

void showCompletionDialog(
    BuildContext context, String title, String message, String? buttonText) {
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
    Share.shareXFiles(xFiles,
        subject: "Split files", text: "Here are the split parts of the file");
  }

  logger.log(Level.info, "Sharing dialog opened.");
}
