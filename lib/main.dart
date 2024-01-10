import 'package:flutter/material.dart';
import 'package:kidspot_app/firebase_options.dart';
import 'sos_page.dart';
import 'location_page.dart';
import 'settings_page.dart';
import 'login_page.dart';
import 'package:firebase_core/firebase_core.dart';
// hello world
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kidspot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          color: Colors.blue,
        ),
        fontFamily: 'Poppins',
      ),
      home: LoginPage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final bool isParent; // Added this to pass to LocationPage and SettingsPage
  final String title;

  const MyHomePage({
    Key? key,
    required this.title,
    required this.isParent, // Pass this from wherever you determine the role
  }) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  late final List<Widget> _pages; // Make this late to initialize in initState

  @override
  void initState() {
    super.initState();
    _pages = [
      SOSPage(isParent: widget.isParent), // Pass the isParent flag here
      LocationPage(isParent: widget.isParent), // Pass the isParent flag
      SettingsPage(isChild: !widget.isParent), // Set isChild based on isParent
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notification',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Location',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
