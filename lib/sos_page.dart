import 'package:flutter/material.dart';

class SOSPage extends StatelessWidget {
  const SOSPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // We have two tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'), // Blue AppBar with Page Name
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.video_call), text: 'Video'),
              Tab(icon: Icon(Icons.message), text: 'Messages'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            VideoMessagesPage(), // Video Messages tab
            TextMessagesPage(),  // Text Messages tab
          ],
        ),
      ),
    );
  }
}

class VideoMessagesPage extends StatelessWidget {
  const VideoMessagesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Video Messages'), // Placeholder for video messages content
    );
  }
}

class TextMessagesPage extends StatelessWidget {
  const TextMessagesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // List of predefined messages that the child can choose to send
    final List<String> predefinedMessages = [
      "I need help!",
      "I'm at school.",
      "Can you pick me up?",
      "I finished my homework.",
      "I'm feeling sick."
    ];

    return ListView.builder(
      itemCount: predefinedMessages.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(predefinedMessages[index]),
          trailing: const Icon(Icons.send),
          onTap: () {
            // Placeholder function to simulate sending a message
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Send this message?"),
                content: Text(predefinedMessages[index]),
                actions: [
                  TextButton(
                    child: const Text("Cancel"),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  TextButton(
                    child: const Text("Send"),
                    onPressed: () {
                      // TODO: Implement message sending logic
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Message sent: ${predefinedMessages[index]}"),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
