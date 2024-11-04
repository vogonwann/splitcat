import 'dart:io';
import 'package:flutter/material.dart';
import 'package:splitcat/pages/custom_screen.dart';
import 'package:splitcat/pages/merge_screen.dart';
import 'package:splitcat/pages/multiple_screen.dart';
import 'package:splitcat/pages/preset_screen.dart';
import 'package:splitcat/pages/qr_code_screen.dart';
import 'package:splitcat/util/catppuccin.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

Future<void> _showAboutDialog(BuildContext context) async {
  String version = '';
  await PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
    version = packageInfo.version;
  });
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('About Splitcat'),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Version: $version",
                style: TextStyle(fontSize: 12.0, color: Colors.grey.shade400),
              ),
              SizedBox(height: 12,),
              SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    _buildLinkRow(
                      icon: Icons.person,
                      text: 'Developed by Ivan Janjić',
                      url: '',
                    ),
                    _buildLinkRow(
                      icon: Icons.link,
                      text: 'GitHub: vogonwann',
                      url: 'https://github.com/vogonwann',
                    ),
                    _buildLinkRow(
                      icon: Icons.language,
                      text: 'Site: janjic.lol',
                      url: 'https://janjic.lol',
                    ),
                    _buildLinkRow(
                      icon: Icons.portrait,
                      text: 'Mastodon: wannoye',
                      url: 'https://mastodon.social/@wannoye',
                    ),
                  ],
                ),
              )
            ]),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

// Funkcija za kreiranje reda sa ikonom i linkom
Widget _buildLinkRow(
    {required IconData icon, required String text, required String url}) {
  return GestureDetector(
    child: InkWell(
      onTap: (() {
        _launchURL(url);
      }),
      hoverColor: Colors.white10,
      splashColor: Colors.white30,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: <Widget>[
          Icon(icon, color: catppuccinAccent), // Možeš prilagoditi boju
          const SizedBox(width: 8), // Razmak između ikone i teksta
          Text(text),
        ],
      ),
    ),
  );
}

// Funkcija za otvaranje URL-a
void _launchURL(String url) async {
  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    throw 'Could not launch $url';
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
    const MultipleScreen(),
    const MergeScreen(),
    const QrCodeScreen()
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openNewScreenWithAnimation(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => QrCodeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Splitcat'),
        backgroundColor: catppuccinSurface,
        actions: [
          IconButton(onPressed: () async {
            _openNewScreenWithAnimation(context);
          }, icon: const Icon(Icons.qr_code),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () async =>
                await _showAboutDialog(context),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        showUnselectedLabels: true,
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
              icon: Icon(Icons.file_copy_sharp),
              label: 'Multiple'
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
