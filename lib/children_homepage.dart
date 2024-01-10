import 'package:flutter/material.dart';
import 'sos_page.dart';
import 'location_page.dart';
import 'settings_page.dart';

class ChildHomePage extends StatefulWidget {
  final String userName;
  final String userEmail;

  ChildHomePage({Key? key, required this.userName, required this.userEmail}) : super(key: key);

  @override
  _ChildHomePageState createState() => _ChildHomePageState();
}

class _ChildHomePageState extends State<ChildHomePage> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      SOSPage(isParent: false),
      LocationPage(isParent: false),
      SettingsPage(isChild: true, userName: widget.userName, userEmail: widget.userEmail),
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
