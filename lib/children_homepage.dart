import 'package:flutter/material.dart';
import 'sos_page.dart';
import 'location_page.dart';
import 'settings_page.dart';

class ChildHomePage extends StatefulWidget {
  @override
  _ChildHomePageState createState() => _ChildHomePageState();
}

class _ChildHomePageState extends State<ChildHomePage> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    SOSPage(isParent: false), // Pass isParent: false here
    LocationPage(isParent: false), // Explicitly pass isParent for child users
    const SettingsPage(isChild: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Location'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
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
