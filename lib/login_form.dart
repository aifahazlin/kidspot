import 'package:flutter/material.dart';
import 'parent_homepage.dart';  // Ensure this file exists with ParentHomePage widget
import 'children_homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginForm extends StatefulWidget {
  final String role; // "parent" or "child"

  LoginForm({Key? key, required this.role}) : super(key: key);

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;

  void _tryLogin() async {
    try {
      // Login using Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Fetch user details
      User? user = userCredential.user;
      if (user != null) {
        String userName = user.displayName ?? "Name";
        String userEmail = user.email ?? "No Email Provided";

        if (widget.role == 'parent') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ParentHomePage(userName: userName, userEmail: userEmail)),
          );
        } else if (widget.role == 'child') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ChildHomePage(userName: userName, userEmail: userEmail)),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // Handle login errors here
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Login Failed'),
          content: Text(e.message ?? 'An error occurred.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

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
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                  icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                ),
              ),
              obscureText: obscurePassword,
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
