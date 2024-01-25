import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QRCodePage extends StatelessWidget {

  final FirebaseAuth _auth = FirebaseAuth.instance;



  @override
  Widget build(BuildContext context) {

    User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Your QR Code'),
      ),
      body: Center(
        child: Image.network(
          'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=' + (user?.uid ?? 'GuestUserID'),
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}
