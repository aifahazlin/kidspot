import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
      // Handle FCM message when the app is opened from the terminated state
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
        'uid': user?.uid,
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

    String notificationTitle = widget.isParent ? 'Your Child' : 'Your Parent';

    // Generate a unique ID for each notification
    String notificationId = Uuid().v1();

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
      String linkedUserIdFields = widget.isParent ? 'parent_id' : 'child_id';


      DatabaseEvent snapshot = await FirebaseDatabase.instance
          .reference()
          .child('linked')
          .orderByChild(linkedUserIdField)
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
