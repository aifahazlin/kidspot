import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:math';
import 'login_page.dart'; // Ensure this file exists in your project.
import 'qrscanner_page.dart';
import 'qrcode_page.dart';
import 'children_homepage.dart'; // Add this import
import 'parent_homepage.dart'; // Add this import

class SettingsPage extends StatefulWidget {
  final bool isChild;
  final String userName;
  final String userEmail;

  const SettingsPage({
    Key? key,
    required this.isChild,
    required this.userName,
    required this.userEmail,
  }) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String _userName;

  @override
  void initState() {
    super.initState();
    _userName = widget.userName;
  }

  String generateRandomString(int length) {
    const _chars = 'abcdefghijklmnopqrstuvwxyz1234567890';
    Random _rnd = Random(); // Ensure dart:math is imported
    return String.fromCharCodes(Iterable.generate(
        length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: <Widget>[
          _userProfileSection(),
          _settingsOption(
            icon: Icons.account_circle,
            title: 'Account Setting',
            onTap: () {
              // Use 'isChild' property here instead of 'isChildFlag'
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    isChild: widget.isChild,
                    userName: widget.userName,
                    userEmail: widget.userEmail,
                  ),
                ),
              );
            },
          ),
          _settingsOption(
            icon: Icons.devices,
            title: 'Linked Devices',
            onTap: () {
              if (widget.isChild) {
                _navigateToQRScannerPage(context);
              } else {
                _showQRCodePage(context);
              }
            },
          ),
          _settingsOption(
            icon: Icons.help,
            title: 'Help',
            onTap: () {
              // TODO: Implement Help logic
            },
          ),
          _settingsOption(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginPage()),
                    (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _userProfileSection() {
    return GestureDetector(
      onTap: () => _editNameDialog(context),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage('assets/images/kidspot_ss.png'),
            ),
            const SizedBox(width: 16.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName.isEmpty ? "Tap to add name" : _userName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.userEmail,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => _editNameDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _editNameDialog(BuildContext context) {
    final TextEditingController _nameController =
    TextEditingController(text: _userName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Name'),
          content: TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Enter your name',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                String newName = _nameController.text.trim();
                setState(() {
                  _userName = newName;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _settingsOption(
      {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }

  void _showQRCodePage(BuildContext context) {
    String qrData = generateRandomString(10);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QRCodePage(),
      ),
    );
  }

  void _navigateToQRScannerPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRScannerPage()),
    );
  }
}
