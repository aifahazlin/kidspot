import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({Key? key}) : super(key: key);

  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _controller;
  String? scannedData;
  String? insertionResult = "Scanning..";

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // Method to handle QR code data
  void _handleQRCode(String? qrData) {
    setState(() {
      scannedData = qrData;
      _insertDataIntoFirebase();
    });
  }

  // Callback for QRView creation
  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      _controller = controller;
    });

    _controller!.scannedDataStream.listen((scanData) {
      // Handle the scanned data using the method
      _handleQRCode(scanData.code);
    });
  }

  // Insert data into Firebase Realtime Database
  void _insertDataIntoFirebase() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    User? user = _auth.currentUser;

    if (user != null && scannedData != null) {
      DatabaseReference databaseReference = FirebaseDatabase.instance.reference();

      // Assuming 'linked' is the node in your database
      // Change this based on your database structure
      DatabaseReference childReference = databaseReference.child('linked').child(user.uid);

      try {
        // Check the count of existing parent_id entries for the specified child_id
        DatabaseEvent event = await childReference.orderByChild('child_id').equalTo(user.uid).once();

        // Debugging statement to print the value of event.snapshot.value
        print('Debug - event.snapshot.value: ${event.snapshot.value}');

        if (event.snapshot.value != null && event.snapshot.value is Map && (event.snapshot.value as Map).length >= 2) {
          // Limit reached, cannot add more parent_id entries for this child_id
          setState(() {
            insertionResult = 'Error: Limit reached, cannot add more parent_id entries for this child_id';
          });
          print('Error: Limit reached, cannot add more parent_id entries for this child_id');
        } else {
          // Check if the same parent_id already exists for the specified child_id
          Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;
          bool parentExists = false;

          if (data != null) {
            // Check if the same parent_id exists
            parentExists = data.values.any((value) => value['parent_id'] == scannedData);
          }

          if (parentExists) {
            // Same parent_id already linked to this child_id
            setState(() {
              insertionResult = 'Error: Same parent_id already linked to this child';
            });
            print('Error: Same parent_id already linked to this child');
          } else {
            // Proceed with insertion
            await childReference.push().set({
              'child_id': user.uid,
              'parent_id': scannedData,
              'timestamp': ServerValue.timestamp,
            });
            setState(() {
              insertionResult = 'Successfully linked child to parent';
            });
            print('Data inserted into Firebase!');
          }
        }
      } catch (error) {
        setState(() {
          insertionResult = 'Error: $error';
        });
        print('Error inserting data into Firebase: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Scanner'),
      ),
      body: Column(
        children: [
          Expanded(
            child: QRView(
              key: _qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  '$insertionResult',
                  style: TextStyle(
                    fontSize: 18.0,
                    color: insertionResult != null && insertionResult!.startsWith('Error') ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
