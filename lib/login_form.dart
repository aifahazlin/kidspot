import 'package:flutter/material.dart';
import 'parent_homepage.dart';  // Ensure this file exists with ParentHomePage widget
import 'children_homepage.dart';

class LoginForm extends StatefulWidget {
  final String role; // "parent" or "child"

  LoginForm({Key? key, required this.role}) : super(key: key);

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _tryLogin() async {
    // TODO: Implement logic to check credentials
    //bool userExists = false; // Replace with actual check

    if (widget.role == 'parent') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ParentHomePage()),
      );
    } else if (widget.role == 'child') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ChildHomePage()),
      );
    }
  }

   //if (!userExists) {
   //   showDialog(
    //    context: context,
    //    builder: (ctx) => AlertDialog(
    //      title: Text('Login Failed'),
    //      content: Text('No account found. Please sign up.'),
    //     actions: <Widget>[
     //       TextButton(
     //         child: Text('OK'),
     //         onPressed: () => Navigator.of(ctx).pop(),
    //        ),
   //       ],
    //    ),
   //   );
   // } else {
   //   // TODO: Navigate to ParentHomePage or ChildHomePage based on widget.role
    //}
  //}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login as ${widget.role.capitalize()}')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _tryLogin,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
