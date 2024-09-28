import 'dart:io';
import 'package:flutter/material.dart';
import 'package:splitcat/pages/custom_screen.dart';
import 'package:splitcat/pages/merge_screen.dart';
import 'package:splitcat/pages/preset_screen.dart';
import 'package:splitcat/util/catppuccin.dart';
import 'package:window_manager/window_manager.dart';

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
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.setAsFrameless();
    });
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

