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
      final archiveEncoded = password == null || password.isEmpty 
        ? ZipEncoder().encode(archive) 
        : ZipEncoder(password: password).encode(archive);
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


/// Splits a file or zipped directory into smaller chunks, with optional encryption.
Future<void> splitFiles(
    FilePickerResult files,
    int chunkSize,
    BuildContext context,
    Function(bool) setIsSplitting,
    Function(String) setCurrentMessage, {
      bool zipBefore = true,
      bool encryptBefore = false,
      String? password,
    }) async {
  if (chunkSize <= 0) {
    logger.e("Chunk size must be > 0.");
    return;
  }

  setIsSplitting(true); // Start splitting process
  final chunkSizeInBytes = chunkSize * 1024 * 1024;

  final zipFile = io.File("${path.dirname(files.files[0].path!)}/splitcat_${DateTime.now()}.zip");
  await zipFile.create();

  final selectedFileName = path.basename(zipFile.path);
  if (zipBefore) {

    logger.i("Creating archive $selectedFileName");
    setCurrentMessage("Creating archive $selectedFileName.zip");
    try {
      try {
        final List<io.File> filesToArchive = List.empty(growable: true);
        for (var file in files.files) {
          filesToArchive.add(io.File(file.path!));
        }
        await farchive.ZipFile.createFromFiles(sourceDir: io.File(files.files[0].path!).parent, files: filesToArchive, zipFile: zipFile);
      } catch (e) {
        logger.e("$e");
      }

      await _processAndSplitFile(zipFile, chunkSizeInBytes, context,
          selectedFileName, setIsSplitting, setCurrentMessage, isZip: true);

      logger.i("Archive $selectedFileName created");
      setCurrentMessage("Archive ${zipFile.path} created");
    } catch (e) {
      logger.e("$e");
    }
  }
}


Future<void> splitFiles2(
    FilePickerResult files,
    int chunkSize,
    BuildContext context,
    Function(bool) setIsSplitting,
    Function(String) setCurrentMessage, {
      bool zipBefore = true,
      bool encryptBefore = false,
      String? password,
    }) async {
  if (chunkSize <= 0) {
    logger.e("Chunk size must be > 0.");
    return;
  }

  setIsSplitting(true); // Start splitting process
  final chunkSizeInBytes = chunkSize * 1024 * 1024;

  var zipFile = io.File("${path.dirname(files.files[0].path!)}/splitcat_${DateTime.now()}.zip");
  await zipFile.create();

  final selectedFileName = path.basename(zipFile.path);
  if (zipBefore) {

    logger.i("Creating archive $selectedFileName");
    setCurrentMessage("Creating archive $selectedFileName.zip");
    try {
      try {
        var archive = Archive();
        for (var file in files.files) {
          var bytes = await io.File(file.path!).readAsBytes();
          var archiveFile = ArchiveFile(path.basename(file.path!), bytes.length, bytes);
          archive.addFile(archiveFile);
        }

        final zipEncoder = ZipEncoder(password: password);
        final encodedArchive = zipEncoder.encode(archive);
        zipFile = await zipFile.writeAsBytes(encodedArchive!);
      } catch (e) {
        logger.e("$e");
      }

      await _processAndSplitFile(zipFile, chunkSizeInBytes, context,
          selectedFileName, setIsSplitting, setCurrentMessage, isZip: true);

      logger.i("Archive $selectedFileName created");
      setCurrentMessage("Archive ${zipFile.path} created");
    } catch (e) {
      logger.e("$e");
    }
  }
}


Future<void> shareFiles(
    FilePickerResult files,
    BuildContext context,
    Function(bool) setIsSplitting,
    Function(String) setQrCode, {
      bool zipBefore = true,
      bool encryptBefore = false,
      String? password,
    }) async {

  String filePath = '';
  if (zipBefore) {
    var zipFile = io.File("${path.dirname(files.files[0].path!)}/splitcat_${DateTime.now()}.zip");
    await zipFile.create();
    final selectedFileName = path.basename(zipFile.path);
    logger.i("Creating archive $selectedFileName");
    setQrCode("Creating archive $selectedFileName.zip");
    try {
      try {
        var archive = Archive();
        for (var file in files.files) {
          var bytes = await io.File(file.path!).readAsBytes();
          var archiveFile = ArchiveFile(path.basename(file.path!), bytes.length, bytes);
          archive.addFile(archiveFile);
        }

        final zipEncoder = ZipEncoder(password: password);
        final encodedArchive = zipEncoder.encode(archive);
        zipFile = await zipFile.writeAsBytes(encodedArchive!);
      } catch (e) {
        logger.e("$e");
      }
      logger.i("Archive $selectedFileName created");

      // await _processAndSplitFile(zipFile, chunkSizeInBytes, context,
      //     selectedFileName, setIsSplitting, setCurrentMessage, isZip: true);
      filePath = zipFile.path;
    } catch (e) {
      logger.e("$e");
    }
  } else {
    filePath = path.dirname(files.files[0].path!);
  }
  startFileServer(filePath);
  var ipAddress = await getLocalIpAddress();
  setQrCode("http://$ipAddress:8080");
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

  final bytes = await io.File(file.path).readAsBytes();
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


Future<void> zipFolder(String sourceDirPath, String zipFilePath) async {
  final encoder = ZipEncoder();
  final archive = Archive();

  Directory sourceDir = Directory(sourceDirPath);
  List<FileSystemEntity> files = sourceDir.listSync(recursive: true);

  for (var file in files) {
    if (file is File) {
      String relativePath = file.path.substring(sourceDir.path.length + 1);
      List<int> bytes = await file.readAsBytes();
      archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
    }
  }

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

Future<String> getLocalIpAddress() async {
  // Get all interfaces and find IPv4 address
  for (var interface in await NetworkInterface.list()) {
    for (var addr in interface.addresses) {
      if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
        return addr.address;
      }
    }
  }
  return '0.0.0.0';
}

void startFileServer(String filePath) async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  logger.i('Server started on: ${server.address.address}:${server.port}');

  await for (HttpRequest request in server) {
    if (request.method == 'GET') {
      final file = File(filePath);
      if (await file.exists()) {
        request.response.headers.contentType = ContentType.binary;

        // Stream the file to the response
        await request.response.addStream(file.openRead());

        // Close the response after streaming the file
        await request.response.close();

        // Close the server after the file has been sent
        await server.close();
        logger.i('Server closed.');
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write("File not found.");
        await request.response.close();
      }
    }
  }
}