import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

Logger get logger => Log.instance;

class Log extends Logger {
  // ignore: deprecated_member_use
  Log._()
      : super(printer: PrettyPrinter(printTime: true, printEmojis: true), output: FileOutput());
  static final instance = Log._();
}

class FileOutput extends LogOutput {
  @override
  void output(OutputEvent event) async {
    final directory = await getApplicationDocumentsDirectory();
    if (directory != null) {
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }
    for (var line in event.lines) {
      print(line); // Ispis u konzolu
      File('${directory?.path}/splitcat.log')
          .writeAsStringSync('$line\n', mode: FileMode.append); // Log u fajl
    }
  }
}
