import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

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
            isParent ? LocationAlertsPage() : VideoMessagesPage(isParent: isParent),
            TextMessagesPage(isParent: isParent),
          ],
        ),
      ),
    );
  }
}

class VideoMessagesPage extends StatefulWidget {
  final bool isParent;
  const VideoMessagesPage({Key? key, required this.isParent}) : super(key: key);

  @override
  _VideoMessagesPageState createState() => _VideoMessagesPageState();
}

class _VideoMessagesPageState extends State<VideoMessagesPage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool isRecording = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller!.initialize();
  }

  void _recordVideo() async {
    if (isRecording) {
      await _controller!.stopVideoRecording();
      setState(() => isRecording = false);
    } else {
      await _controller!.startVideoRecording();
      setState(() => isRecording = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller!),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: RecordButton(
                      isRecording: isRecording,
                      onPressed: _recordVideo,
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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

class LocationAlertsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Implementation for LocationAlertsPage for parent users
    return ListView.builder(
      itemCount: 5,  // Replace with actual data length
      itemBuilder: (context, index) {
        return ListTile(
          leading: Icon(Icons.location_on),
          title: Text('Child left school area'),  // Replace with actual data
          subtitle: Text('10 mins ago'),  // Replace with actual data
        );
      },
    );
  }
}

class TextMessagesPage extends StatefulWidget {
  final bool isParent;
  const TextMessagesPage({Key? key, required this.isParent}) : super(key: key);

  @override
  _TextMessagesPageState createState() => _TextMessagesPageState();
}

class _TextMessagesPageState extends State<TextMessagesPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> predefinedMessagesForChild = [
    "I need help!",
    "I'm at school.",
    "Can you pick me up?",
    "I finished my homework.",
    "I'm feeling sick.",
  ];
  final List<String> predefinedMessagesForParent = [
    "Are you okay?",
    "Did you reach school?",
    "Call me when you can.",
    "Remember to take your lunch.",
    "I love you!"
  ];
  final List<String> messagesFromChild = []; // Placeholder for received messages

  void _sendMessage(String? message) {
    // Logic to send the message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Message sent: $message")),
    );
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isParent) {
      // Parent functionality
      return Column(
        children: [
          // Predefined messages section
          Expanded(
            child: ListView.builder(
              itemCount: predefinedMessagesForParent.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(predefinedMessagesForParent[index]),
                  trailing: const Icon(Icons.send),
                  onTap: () => _sendMessage(predefinedMessagesForParent[index]),
                );
              },
            ),
          ),
          // Custom message section
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
                      hintText: "Write a message to your child...",
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
          // Messages received from child
          Expanded(
            child: ListView.builder(
              itemCount: messagesFromChild.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text("From child: ${messagesFromChild[index]}"),
                  leading: const Icon(Icons.child_care),
                );
              },
            ),
          ),
        ],
      );
    } else {
      // Child functionality
      return Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: predefinedMessagesForChild.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(predefinedMessagesForChild[index]),
                  trailing: const Icon(Icons.send),
                  onTap: () => _sendMessage(predefinedMessagesForChild[index]),
                );
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
      );
    }
  }
}
