import 'dart:io';

import 'package:logger/logger.dart';
Logger get logger => Log.instance;

class Log extends Logger {
  // ignore: deprecated_member_use
  Log._() : super(printer: PrettyPrinter(printTime: true), output: FileOutput());
  static final instance = Log._();
}

class FileOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      print(line); // Ispis u konzolu
      File('log.txt')
          .writeAsStringSync('$line\n', mode: FileMode.append); // Log u fajl
    }
  }
}