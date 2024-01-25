import 'package:flutter/material.dart';
import 'sos_page.dart';
import 'location_page.dart';
import 'settings_page.dart';

class ParentHomePage extends StatefulWidget {
  final String userName;
  final String userEmail;

  ParentHomePage({Key? key, required this.userName, required this.userEmail}) : super(key: key);
  @override
  _ParentHomePageState createState() => _ParentHomePageState();
}

class _ParentHomePageState extends State<ParentHomePage> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      SOSPage(isParent: true),
      LocationPage(isParent: true),
      SettingsPage(isChild: false, userName: widget.userName, userEmail: widget.userEmail),
    ];
  }

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