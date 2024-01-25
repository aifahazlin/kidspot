import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class SOSPage extends StatelessWidget {
  final bool isParent;
  const SOSPage({Key? key, required this.isParent}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isParent ? 'Parent Dashboard' : 'Child Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
              Tab(icon: Icon(Icons.message), text: 'Text Messages'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            isParent
                ? LocationAlertsPage()
                : EmergencyCallButton(), // Use EmergencyCallButton for video message
            isParent
                ? TextMessagesPage(isParent: isParent)
                : TextMessagesPage(isParent: isParent),
          ],
        ),
      ),
    );
  }
}

class EmergencyCallButton extends StatefulWidget {
  @override
  _EmergencyCallButtonState createState() => _EmergencyCallButtonState();
}

class _EmergencyCallButtonState extends State<EmergencyCallButton> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            // Implement the logic for the emergency call here
            // You can show a dialog, make a call, or perform any other emergency action
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Emergency Call'),
                content: Text('Call 911 or your emergency contact.'),
                actions: <Widget>[
                  TextButton(
                    child: Text('OK'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          },
          child: CircleAvatar(
            radius: 100,
            backgroundColor: Colors.red,
            child: Icon(
              Icons.phone,
              size: 80,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 20),
        GestureDetector(
          onTap: () {
            // Display dialog box to add contact
            _showAddContactDialog(context);
          },
          child: Text(
            'Tap to add Contact!',)

        ),
      ],
    );
  }

  void _showAddContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        String successMessage = ''; // Message to display after saving contact
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Emergency Contact'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _contactController,
                    decoration: InputDecoration(
                      labelText: 'Contact Number',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 10),
                  Text(
                    successMessage,
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: Text('Save'),
                  onPressed: () {
                    // Implement the logic to save the contact
                    String name = _nameController.text;
                    String contactNumber = _contactController.text;
                    // You can save the contact to your data storage or perform any other action
                    print('Contact saved: $name, $contactNumber');
                    successMessage = 'Contact saved successfully';
                    setState(() {}); // Redraw the dialog to show the success message
                    _clearFields(); // Clear the text fields
                    // Introduce a delay before closing the dialog
                    Future.delayed(Duration(seconds: 2), () {
                      Navigator.of(context).pop(); // Close the dialog after delay
                    });
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _clearFields() {
    _nameController.clear();
    _contactController.clear();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    super.dispose();
  }
}
  final DatabaseReference _databaseReference =
  FirebaseDatabase.instance.reference().child('locations');

  Position? _previousLocation;


  Future<void> startLocationTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Handle the case where the user denies permission
        return;
      }
    }

    // Get the initial location
    Position initialLocation = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    // Insert the initial location into Firebase
    _insertLocationIntoFirebase(initialLocation);

    // Set up the location callback
    Geolocator.getPositionStream(

    ).listen((Position position) {
      // Check if the location has changed
      if (_locationChanged(position)) {
        // Handle the location update here
        //print("Location: ${position.latitude}, ${position.longitude}");

        // Insert the location into Firebase with timestamp
        _insertLocationIntoFirebase(position);
      }
    });
  }

  bool _locationChanged(Position newLocation) {
    if (_previousLocation == null) {
      return true;
    }

    // Get the first four characters of latitude and longitude
    String newLatStr = newLocation.latitude.toStringAsFixed(4);
    String newLonStr = newLocation.longitude.toStringAsFixed(4);
    String prevLatStr = _previousLocation!.latitude.toStringAsFixed(4);
    String prevLonStr = _previousLocation!.longitude.toStringAsFixed(4);

    bool hasChanged = newLatStr != prevLatStr || newLonStr != prevLonStr;

    print("New Latitude: $newLatStr");
    print("Previous Latitude: $prevLatStr");
    print("New Longitude: $newLonStr");
    print("Previous Longitude: $prevLonStr");
    print("Location has changed: $hasChanged");

    return hasChanged;
  }


  Future<bool> checkInitialLocation() async {
    // Check if there is any data in the database
    DatabaseEvent event = await _databaseReference.once();

    // Assuming 'DatabaseEvent' has a property named 'snapshot'
    return event.snapshot.value != null;
  }


  void _insertLocationIntoFirebase(Position position) {

    final FirebaseAuth _auth = FirebaseAuth.instance;
    User? user = _auth.currentUser;

    final Map<String, dynamic> locationData = {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'child_id' : user?.uid,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // Insert the location into Firebase with a unique key
    _databaseReference.push().set(locationData);

    // Update the previous location
    _previousLocation = position;
  }

  void _insertLocationIntoFirebases(Position position) {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    User? user = _auth.currentUser;

    // Get the first four characters of latitude and longitude
    String currentLatStr = position.latitude.toStringAsFixed(4);
    String currentLonStr = position.longitude.toStringAsFixed(4);

    if (_previousLocation == null ||
        currentLatStr != _previousLocation!.latitude.toStringAsFixed(4) ||
        currentLonStr != _previousLocation!.longitude.toStringAsFixed(4)) {
      _insertLocationIntoFirebase(position);
    }
  }



class RecordButton extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onPressed;

  const RecordButton({Key? key, required this.isRecording, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: CircleAvatar(
        radius: 30,
        backgroundColor: isRecording ? Colors.red[800] : Colors.blue,
        child: Icon(
          isRecording ? Icons.stop : Icons.videocam,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }
}

class LocationAlertsPage extends StatefulWidget {
  @override
  _LocationAlertsPageState createState() => _LocationAlertsPageState();
}

class _LocationAlertsPageState extends State<LocationAlertsPage> {
  DatabaseReference _databaseReferenceLocations =
  FirebaseDatabase.instance.reference().child('locations');
  DatabaseReference _databaseReferenceLinks =
  FirebaseDatabase.instance.reference().child('linked');

  List<Map<String, dynamic>> locationData = [];

  String _calculateTimeDifference(int timestamp) {
    var now = DateTime.now().millisecondsSinceEpoch;
    var difference = now - timestamp;

    if (difference < 60000) {
      return 'Just now';
    } else if (difference < 3600000) {
      var minutes = (difference / 60000).round();
      return '$minutes min ago';
    } else if (difference < 86400000) {
      var hours = (difference / 3600000).round();
      return '$hours hours ago';
    } else {
      var days = (difference / 86400000).round();
      return '$days days ago';
    }
  }

  @override
  void initState() {
    super.initState();

    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      Position currentLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final FirebaseAuth _auth = FirebaseAuth.instance;
      User? user = _auth.currentUser;

      _databaseReferenceLinks
          .orderByChild('parent_id')
          .equalTo(user?.uid)
          .once()
          .then((DatabaseEvent event) {
        Map<dynamic, dynamic>? linkedData =
        event.snapshot.value as Map<dynamic, dynamic>;

        if (linkedData != null) {
          List<dynamic> childIds = linkedData.keys.toList();

          _databaseReferenceLocations.onValue.listen((DatabaseEvent event) {
            // Handle data updates here
            if (event.snapshot.value != null) {
              setState(() {
                locationData.clear();
                Map<dynamic, dynamic>? values =
                event.snapshot.value as Map<dynamic, dynamic>;

                if (values != null) {
                  values.forEach((key, value) {
                    if (value is Map<dynamic, dynamic> &&
                        childIds.contains(value['child_id'])) {
                      locationData.add(Map<String, dynamic>.from(value));
                    }
                  });
                }
              });
            }
          });
        }
      });
    } catch (e) {
      print('Error getting user location: $e');
    }
  }

  Future<String> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        String fullAddress = '';

        fullAddress += placemark.subThoroughfare ?? '';
        fullAddress +=
        placemark.thoroughfare != null ? placemark.thoroughfare! + ', ' : '';
        fullAddress +=
        placemark.locality != null ? placemark.locality! + ', ' : '';
        fullAddress +=
        placemark.administrativeArea != null ? placemark.administrativeArea! + ', ' : '';
        fullAddress +=
        placemark.postalCode != null ? placemark.postalCode! + ', ' : '';
        fullAddress += placemark.country != null ? placemark.country! : '';

        return fullAddress;
      } else {
        return 'No address found';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<double> calculateDistance(
      double latitude, double longitude, Position userLocation) async {
    double distanceInMeters = await Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      latitude,
      longitude,
    );

    // Convert distance to kilometers
    double distanceInKm = distanceInMeters / 1000;
    return distanceInKm;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Position>(
      future: Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        } else {
          Position userLocation = snapshot.data!;

          return ListView.builder(
            itemCount: locationData.length,
            itemBuilder: (context, index) {
              double latitude = locationData[index]['latitude'];
              double longitude = locationData[index]['longitude'];
              int timestamp = locationData[index]['timestamp'];

              return FutureBuilder<double>(
                future: calculateDistance(latitude, longitude, userLocation),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      title: Text('Loading...'),
                    );
                  } else if (snapshot.hasError) {
                    return ListTile(
                      title: Text('Error: ${snapshot.error}'),
                    );
                  } else {
                    double distanceInKm = snapshot.data ?? 0.0;

                    return ListTile(
                      leading: Column(
                        children: [
                          Icon(Icons.location_on),
                          Text('${distanceInKm.toStringAsFixed(2)} km'),
                        ],
                      ),
                      title: FutureBuilder<String>(
                        future: getAddressFromCoordinates(latitude, longitude),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Text('Loading...');
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else {
                            String address = snapshot.data ?? 'Unknown address';
                            return Text(address);
                          }
                        },
                      ),
                      subtitle: Text(_calculateTimeDifference(timestamp)),
                    );
                  }
                },
              );
            },
          );
        }
      },
    );
  }
}


String _calculateTimeDifference(int timestamp) {
  var now = DateTime.now().millisecondsSinceEpoch;
  var difference = now - timestamp;

  if (difference < 60000) {
    return 'Just now';
  } else if (difference < 3600000) {
    var minutes = (difference / 60000).round();
    return '$minutes min ago';
  } else if (difference < 86400000) {
    var hours = (difference / 3600000).round();
    return '$hours hours ago';
  } else {
    var days = (difference / 86400000).round();
    return '$days days ago';
  }
}

class TextMessagesPage extends StatefulWidget {
  final bool isParent;

  const TextMessagesPage({Key? key, required this.isParent}) : super(key: key);

  @override
  _TextMessagesPageState createState() => _TextMessagesPageState();
}

class _TextMessagesPageState extends State<TextMessagesPage> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final TextEditingController _messageController = TextEditingController();
  late DatabaseReference _messagesRef;

  @override
  void initState() {
    super.initState();
    _messagesRef = FirebaseDatabase.instance.reference().child('messages');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("onMessage: $message");
      // Handle FCM message when the app is in the foreground
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("onMessageOpenedApp: $message");
      // Handle FCM message when the app is opened from terminated state
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    _firebaseMessaging.getToken().then((String? token) {
      print("FCM Token: $token");
    });
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print("Handling a background message: ${message.messageId}");
    // Handle FCM message when the app is in the background
  }

  void _sendMessage(String? message) async {
    if (message != null && message.isNotEmpty) {

      final FirebaseAuth _auth = FirebaseAuth.instance;
      User? user = _auth.currentUser;

      _messagesRef.push().set({
        'uid' : user?.uid,
        'fromParent': widget.isParent,
        'message': message,
        'timestamp': DateTime.now().toUtc().toString(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Message sent: $message")),
      );

      List<String> linkedUserTokens = await _getLinkedUserTokens();
      _sendNotification(message, linkedUserTokens);

      _messageController.clear();
    }
  }


  void _sendNotification(String message, List<String> recipientTokens) async {
    final String serverKey = 'AAAAxgJz7V0:APA91bGoYRSJcCMWk8DjP-i3yZidiv8Vv8vUuzorWvjazafeMKXrfigBVr7_USkgiKgjZIkq05TC_VOaARH8AkxuemQyneIlwGtwSS7wIeaSXMdVjyeIqrwlNhz_9D9Q-fYZC96okj4l';
    final String fcmEndpoint = 'https://fcm.googleapis.com/fcm/send';

    // Generate a unique ID for each notification
    String notificationId = Uuid().v1();

    String notificationTitle = widget.isParent ? 'Your Parent' : 'Your Child';


    final Map<String, dynamic> data = {
      'notification': {'title': notificationTitle, 'body': message},
      'data': {
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        'id': notificationId,
        'status': 'done',
      },
      'registration_ids': recipientTokens, // Use 'registration_ids' for multiple recipients
    };

    final http.Response response = await http.post(
      Uri.parse(fcmEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print('Error sending notification: ${response.reasonPhrase}');
    }
  }


  Future<List<String>> _getLinkedUserTokens() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String currentUserId = user.uid;


      String linkedUserIdField = widget.isParent ? 'parent_id' : 'child_id';
      String linkedUserIdFields = widget.isParent ? 'child_id' : 'parent_id';

      DatabaseEvent snapshot = await FirebaseDatabase.instance
          .reference()
          .child('linked')
          .orderByChild(linkedUserIdField) // Order by parent_id
          .equalTo(currentUserId)
          .once();

      List<String> linkedUserIds = [];

      if (snapshot.snapshot.value != null) {
        Map<dynamic, dynamic>? linkedUsersMap = snapshot.snapshot.value as Map<dynamic, dynamic>?;

        if (linkedUsersMap != null) {
          linkedUsersMap.forEach((key, value) {
            if (value != null && value[linkedUserIdFields] != null) {
              linkedUserIds.add(value[linkedUserIdFields]);
            }
          });
        }
      }

      // Fetch FCM tokens of linked users from the 'users' node
      List<String> linkedUserTokens = await _getLinkedUserTokensFromUsers(linkedUserIds);
      return linkedUserTokens;
    }

    return [];
  }

  Future<List<String>> _getLinkedUserTokensFromUsers(List<String> linkedUserIds) async {
    List<String> linkedUserTokens = [];

    for (String userId in linkedUserIds) {
      DatabaseEvent userSnapshot = await FirebaseDatabase.instance
          .reference()
          .child('users')
          .child(userId)
          .once();

      if (userSnapshot.snapshot.value != null) {
        Map<dynamic, dynamic>? userData = userSnapshot.snapshot.value as Map<dynamic, dynamic>?;

        if (userData != null && userData['fcmToken'] != null) {
          linkedUserTokens.add(userData['fcmToken']);
        }
      }
    }

    return linkedUserTokens;
  }

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    User? user = _auth.currentUser;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _messagesRef.orderByChild('uid').equalTo(user?.uid).onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.hasData) {
                  Map<dynamic, dynamic>? messagesMap =
                  snapshot.data?.snapshot.value as Map<dynamic, dynamic>?;
                  List<String> messages = [];

                  if (messagesMap != null) {
                    messagesMap.forEach((key, value) {
                      if (value['fromParent'] == widget.isParent) {
                        messages.add(value['message']);
                      }
                    });
                  }

                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(messages[index]),
                        trailing: const Icon(Icons.send),
                        onTap: () => _sendMessage(messages[index]),
                      );
                    },
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "Write a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    minLines: 1,
                    maxLines: 5,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () => _sendMessage(_messageController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}