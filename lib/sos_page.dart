import 'package:flutter/material.dart';
import 'package:camera/camera.dart';


class SOSPage extends StatelessWidget {
  const SOSPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.video_call), text: 'Video'),
              Tab(icon: Icon(Icons.message), text: 'Messages'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            VideoMessagesPage(),
            TextMessagesPage(),
          ],
        ),
      ),
    );
  }
}

class VideoMessagesPage extends StatefulWidget {
  const VideoMessagesPage({Key? key}) : super(key: key);

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
      ResolutionPreset.low, // Change to a lower resolution
    );

    _initializeControllerFuture = _controller!.initialize();
  }

  void _recordVideo() async {
    if (isRecording) {
      // Stop recording
      await _controller!.stopVideoRecording();
      setState(() {
        isRecording = false;
      });
    } else {
      // Start recording
      await _controller!.startVideoRecording();
      setState(() {
        isRecording = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // If the Future is complete, display the camera preview
          return Column(
            children: [
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
              ElevatedButton(
                onPressed: _recordVideo,
                child: Text(isRecording ? 'Stop Recording' : 'Record Video'),
              ),
            ],
          );
        } else {
          // Otherwise, display a loading indicator
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

class TextMessagesPage extends StatefulWidget {
  const TextMessagesPage({Key? key}) : super(key: key);

  @override
  _TextMessagesPageState createState() => _TextMessagesPageState();
}

class _TextMessagesPageState extends State<TextMessagesPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> predefinedMessages = [
    "I need help!",
    "I'm at school.",
    "Can you pick me up?",
    "I finished my homework.",
    "I'm feeling sick.",
  ];

  void _sendMessage(String? message) {
    if (message != null && message.isNotEmpty) {
      // TODO: Implement the logic to send the message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Message sent: $message"),
          backgroundColor: Colors.green,
        ),
      );
      _messageController.clear(); // Clear the text field
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: predefinedMessages.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(predefinedMessages[index]),
                trailing: const Icon(Icons.send),
                onTap: () => _sendMessage(predefinedMessages[index]),
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
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "Write a message...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(25.0)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  minLines: 1,
                  maxLines: 5,
                ),
              ),
              const SizedBox(width: 10),
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
