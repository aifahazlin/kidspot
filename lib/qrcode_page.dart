import 'package:flutter/material.dart';

class QRCodePage extends StatelessWidget {
  final String qrData;

  QRCodePage({Key? key, required this.qrData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your QR Code'),
      ),
      body: Center(
        child: Image.network(
          'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=$qrData',
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}
