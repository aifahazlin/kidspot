import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:math';
import 'login_page.dart';  // Ensure this file exists in your project.
import 'qrscanner_page.dart';
import 'qrcode_page.dart';

class SettingsPage extends StatelessWidget {
  final bool isChild;

  const SettingsPage({Key? key, required this.isChild}) : super(key: key);

  // Generate a random string for the QR code
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
            context,
            icon: Icons.account_circle,
            title: 'Account Setting',
            onTap: () {
              // TODO: Implement Account Setting logic
            },
          ),
          _settingsOption(
            context,
            icon: Icons.devices,
            title: 'Linked Devices',
            onTap: () {
              if (isChild) {
                _navigateToQRScannerPage(context);
              } else {
                _showQRCodePage(context);  // This will open the new QR Code page
              }
            },
          ),
          _settingsOption(
            context,
            icon: Icons.help,
            title: 'Help',
            onTap: () {
              // TODO: Implement Help logic
            },
          ),
          _settingsOption(
            context,
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              // Implement Logout logic
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
    return Container(
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
                'User Name',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'user@example.com',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    ); return Container();  // Placeholder
  }

  Widget _settingsOption(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  void _showQRCodePage(BuildContext context) {
    String qrData = generateRandomString(10);

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => QRCodePage(qrData: qrData),
    ));
  }

  void _navigateToQRScannerPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRScannerPage()),
    );
  }
}
