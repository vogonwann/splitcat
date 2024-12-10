import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:splitcat/pages/custom_screen.dart';
import 'package:splitcat/pages/merge_screen.dart';
import 'package:splitcat/pages/multiple_screen.dart';
import 'package:splitcat/pages/preset_screen.dart';
import 'package:splitcat/pages/qr_code_screen.dart';
import 'package:splitcat/util/catppuccin.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  final localization = AppLocalizations.of(context);
  await PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
    version = packageInfo.version;
  });
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(localization!.about_title),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${localization.about_version} $version",
                style: TextStyle(fontSize: 12.0, color: Colors.grey.shade400),
              ),
              SizedBox(height: 12,),
              SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    _buildLinkRow(
                      icon: Icons.person,
                      text: localization.about_developedBy,
                      url: '',
                    ),
                    _buildLinkRow(
                      icon: Icons.link,
                      text: localization.about_github,
                      url: 'https://github.com/vogonwann',
                    ),
                    _buildLinkRow(
                      icon: Icons.language,
                      text: localization.about_site,
                      url: 'https://janjic.lol',
                    ),
                    _buildLinkRow(
                      icon: Icons.portrait,
                      text: localization.about_mastodon,
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
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('sr', ''), // Serbian (Српски)
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
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
    final localizations = AppLocalizations.of(context);
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
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: localizations!.bottomNavigationBar_preset,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: localizations.bottomNavigationBar_custom,
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.file_copy_sharp),
              label: localizations.bottomNavigationBar_multiple
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.merge_type),
            label: localizations.bottomNavigationBar_merge,
          ),
        ],
      ),
    );
  }
}
