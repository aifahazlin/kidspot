import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class QRScannerPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  final String childUserId = "123"; // Define childUserId

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      if (Platform.isAndroid) {
        controller!.pauseCamera();
      } else if (Platform.isIOS) {
        controller!.resumeCamera();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Scanner'),
      ),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      // Ensure scanData.code is not null before processing
      if (scanData.code != null) {
        var parts = scanData.code!.split(':');
        if (parts.length == 3 && parts[0] == 'kidspot' && parts[1] == 'parent') {
          String parentUserId = parts[2];
          // Link child's user ID with parent's user ID in Firestore
          _linkChildWithParent(childUserId, parentUserId);
        }
      controller.pauseCamera();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('QR Code Scanned'),
          content: Text('Scanned data: ${scanData.code}'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Close the QR scanner page
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }}
    );
  }

  void _linkChildWithParent(String childUserId, String parentUserId) {
    // Assuming you have a 'children' collection where each document represents a child
    FirebaseFirestore.instance.collection('children').doc(childUserId).update({
      'parentUserId': parentUserId,
      // Any other data you need to update
    }).then((_) {
      print('Child linked with parent successfully.');
    }).catchError((error) {
      print('Error linking child with parent: $error');
    });
  }


  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
