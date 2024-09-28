import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logger/logger.dart';
import 'package:window_manager/window_manager.dart';

const catppuccinBackground = Color(0xFF24273A);
const catppuccinSurface = Color(0xFF2F334D);
const catppuccinText = Color(0xFFD9E0EE);
const catppuccinPrimary = Color(0xFF8AADF4);
const catppuccinAccent = Color(0xFFF5E0DC);

// Inicijalizacija logera
var logger = Logger(
  printer: PrettyPrinter(),
  output: FileOutput(),
);

Future<String?> getCPUArchitecture() async {
  if (Platform.isWindows) {
    var cpu = Platform.environment['PROCESSOR_ARCHITECTURE'];
    return cpu;
  } else {
    var info = await Process.run('uname', ['-m']);
    var cpu = info.stdout.toString().replaceAll('\n', '');
    return cpu;
  }
}

void main() async {
  runApp(const MyApp());
  var arch = await getCPUArchitecture(); 
  if (arch == "aarch64" || arch == "arm64") {
    windowManager.waitUntilReadyToShow().then((_) async{
        await windowManager.setAsFrameless();
    });
  }
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Splitcat',
      theme: ThemeData(
        scaffoldBackgroundColor: catppuccinBackground,
        colorScheme: const ColorScheme.dark(
          primary: catppuccinPrimary,
          surface: catppuccinSurface,
          onPrimary: catppuccinText,
          onSurface: catppuccinText,
        ),
        textTheme: const TextTheme(
          bodySmall: TextStyle(color: catppuccinText),
          bodyMedium: TextStyle(color: catppuccinText),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: catppuccinSurface,
          selectedItemColor: catppuccinPrimary,
          unselectedItemColor: catppuccinText.withOpacity(0.5),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const PresetScreen(),
    const CustomSplitScreen(),
    const MergeScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Splitcat'),
        backgroundColor: catppuccinSurface,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Preset',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: 'Custom',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.merge_type),
            label: 'Merge',
          ),
        ],
      ),
    );
  }
}

class PresetScreen extends StatefulWidget {
  const PresetScreen({super.key});

  @override
  _PresetScreenState createState() => _PresetScreenState();
}

class _PresetScreenState extends State<PresetScreen> {
  String? selectedFileName;
  String? selectedFilePath;
  String? selectedApplicationName;
  IconData? selectedFileIcon;
  bool isSplitting = false;
  bool isFinished = false;

  final List<Map<String, dynamic>> appLimits = [
    {'App': 'Telegram', 'Limit': 2048, 'Icon': Icons.message}, // 2GB
    {'App': 'Discord', 'Limit': 25, 'Icon': Icons.discord}, // 25MB
    {'App': 'WhatsApp', 'Limit': 2048, 'Icon': Icons.chat}, // 2GB
    {'App': 'Viber', 'Limit': 200, 'Icon': Icons.phone}, // 200MB
    {'App': 'Skype', 'Limit': 300, 'Icon': Icons.video_call}, // 300MB
    {'App': 'Teams', 'Limit': 250, 'Icon': Icons.group}, // 250MB
    {'App': 'Mail', 'Limit': 25, 'Icon': Icons.mail}, // 250MB
  ];

  void splitFile(String filePath, int chunkSize) async {
    if (chunkSize <= 0) {
      logger.e("Chunk size mora biti veći od 0.");
      return;
    }

    setState(() {
      isSplitting = true;
      isFinished = false;
    });

    int chunkSizeInBytes = chunkSize * 1024 * 1024;
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
      String chunkFileName = '$filePath.part${(i + 1) < 10 ? "0${i + 1}" : i + 1}';
      var chunkFile = File(chunkFileName);
      await chunkFile.writeAsBytes(chunkBytes);
      logger.i("Sačuvan chunk $chunkFileName");
    }

    logger.i("Fajl je uspešno podeljen u $nrOfChunks chunk-ova.");

    setState(() {
      isSplitting = false; // Postavi na false kada završi
      isFinished = true;
    });

    showCompletionDialog(context, "File $selectedFileName splited successfully.");
  }

  void showCompletionDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Split finished"),
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

  IconData getIconForFileType(String filePath) {
    String extension = filePath.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mkv':
        return Icons.movie;
      case 'mp3':
      case 'wav':
        return Icons.music_note;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isSplitting) ...[
          const SimpleDialog(
            elevation: 0.0,
            backgroundColor:
                catppuccinBackground, // can change this to your prefered color
            children: <Widget>[
              Center(
                child: CircularProgressIndicator(),
              )
            ],
          ), // Prikaz indikatora
        ] else
          Expanded(
            child: ListView.builder(
              itemCount: appLimits.length,
              itemBuilder: (context, index) {
                return Card(
                  color: catppuccinSurface,
                  child: ListTile(
                    leading:
                        Icon(appLimits[index]['Icon'], color: catppuccinAccent),
                    title: Text(
                      appLimits[index]['App'],
                      style: const TextStyle(color: catppuccinText),
                    ),
                    subtitle: Text(
                      'Limit: ${appLimits[index]['Limit']} MB',
                      style: TextStyle(color: catppuccinText.withOpacity(0.7)),
                    ),
                    onTap: () async {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles();
                      if (result != null) {
                        setState(() {
                          selectedApplicationName = appLimits[index]['App'];
                          selectedFilePath = result.files.single.path;
                          selectedFileName = result.files.single.name;
                          selectedFileIcon =
                              getIconForFileType(result.files.single.path!);
                        });
                        logger.i("Odabran fajl: $selectedFileName");
                        logger.i("Odabran fajl: $selectedFilePath");
                      }
                    },
                  ),
                );
              },
            ),
          ),
        if (selectedFileName != null) ...[
          if (!isSplitting) ...{
            if (!isFinished)
              ListTile(
                leading: Icon(selectedFileIcon, color: catppuccinPrimary),
                title: Text(
                  selectedFileName!,
                  style: const TextStyle(color: catppuccinText),
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    var matchedApp = appLimits.firstWhere(
                      (element) =>
                          selectedApplicationName!.contains(element['App']),
                      orElse: () => {'App': '', 'Limit': 0},
                    );

                    logger.i("Odabran fajl: $selectedFileName");
                    logger.i("Poklapanje: $matchedApp");

                    if (matchedApp['Limit'] > 0) {
                      int limit = matchedApp['Limit'];
                      splitFile(selectedFilePath!, limit);
                      logger.i(
                          "Pokrenut split fajla: $selectedFileName sa limitom $limit MB");
                    } else {
                      logger.e(
                          "Nema poklapanja sa unapred definisanim aplikacijama.");
                    }
                  },
                  child: const Text('Split'),
                ),
              )
          } else
            Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ListTile(
                    leading: Icon(selectedFileIcon, color: catppuccinPrimary),
                    title: Text(
                      selectedFileName!,
                      style: const TextStyle(color: catppuccinText),
                    ),
                  ),
                ])
        ],
      ],
    );
  }
}

class CustomSplitScreen extends StatefulWidget {
  const CustomSplitScreen({super.key});

  @override
  _CustomSplitScreenState createState() => _CustomSplitScreenState();
}

class _CustomSplitScreenState extends State<CustomSplitScreen> {
  String? selectedFileName;
  String? selectedFilePath;
  IconData? selectedFileIcon;
  final TextEditingController _sizeController = TextEditingController();

  // Stub funkcija za splitovanje
  void splitFile(String filePath, int chunkSize) async {
    // Pretvori chunkSize u bajtove (MB * 1024 * 1024)
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
      String chunkFileName = '$filePath.part${(i + 1) < 10 ? "0${i + 1}" : {i + 1}}';
      var chunkFile = File(chunkFileName);

      // Snimi chunk u fajl
      await chunkFile.writeAsBytes(chunkBytes);

      logger.d("Sačuvan chunk $chunkFileName");
    }

    logger.log(Level.info, "Fajl je uspešno podeljen u $nrOfChunks chunk-ova.");
    showCompletionDialog(context, "File $selectedFileName splited successfully.");
  }

  void showCompletionDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Split finished"),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 40, vertical: 20), // Veće dugme
            ),
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles();
              if (result != null) {
                setState(() {
                  selectedFilePath = result.files.single.path;
                  selectedFileName = result.files.single.name;
                  selectedFileIcon = Icons.insert_drive_file; // Primer ikone
                });
              }
            },
            child: const Text('Browse File'),
          ),
          if (selectedFileName != null) ...[
            ListTile(
              leading: Icon(selectedFileIcon),
              title: Text(selectedFileName!),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(24),
            child: TextField(
              controller: _sizeController,
              decoration: const InputDecoration(
                labelText: 'Enter chunk size in MB',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            ),
            onPressed: selectedFileName != null &&
                    _sizeController.text.isNotEmpty
                ? () {
                    int chunkSize = int.tryParse(_sizeController.text) ?? 0;
                    splitFile(selectedFilePath!, chunkSize);
                  }
                : null, // Disable ako fajl nije odabran ili chunk size nije unet
            child: const Text('Split File'),
          ),
        ],
      ),
    );
  }
}

class MergeScreen extends StatefulWidget {
  const MergeScreen({super.key});

  @override
  _MergeScreenState createState() => _MergeScreenState();
}

class _MergeScreenState extends State<MergeScreen> {
  String? selectedFileName;
  IconData? selectedFileIcon;
  bool isMerging = false;
  List<PlatformFile> selectedFiles = List.empty();

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
      final firstFileExtension = filePaths[0].split('.')[filePaths[0].split('.').length - 1];
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

          showCompletionDialog(context, "File $selectedFileName merged successfully.");
        } catch (e) {
          logger.log(Level.error, "Error merging files: $e");
          showCompletionDialog(context, "File $selectedFileName merging failed.");
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
                if (Platform.isLinux) {
                FilePickerResult? result =
                    await FilePickerLinux().pickFiles(allowMultiple: true);
                if (result != null) {
                  setState(() {
                    selectedFileName = result.files.first.name.split('.').removeAt(0);
                    selectedFileIcon = Icons.insert_drive_file; // Primer ikone
                    selectedFiles = result.files;
                  });
                }
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
                      mergeFiles(
                          selectedFiles.map((file) => file.path!).toList());
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
