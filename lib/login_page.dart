import 'package:flutter/material.dart';
import 'main.dart';
import 'signup_page.dart';
import 'login_form.dart';
import 'parent_homepage.dart';  // Ensure this file exists with ParentHomePage widget
import 'children_homepage.dart';   // Ensure this file exists with ChildHomePage widget
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';

class LoginPage extends StatelessWidget {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await firebaseAuth.signInWithCredential(credential);
        // Check if sign in was successful
        if (userCredential.user != null) {
          // Redirect the user to the HomePage or similar
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MyHomePage(isParent: true, title: 'Home')), // Adjust as needed
          );
        }
      }
    } catch (error) {
      // Handle the error, e.g. show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to sign in with Google: $error")),
      );
    }
  }

  void _showSignUpOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sign Up'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ElevatedButton(
                child: Text('Sign in with Google'),
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                  signInWithGoogle(context);
                },
                style: ElevatedButton.styleFrom(primary: Colors.red),
              ),
              ElevatedButton(
                child: Text('Sign up manually'),
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpPage()),
                  );
                },
                style: ElevatedButton.styleFrom(primary: Colors.blue),
              ),
            ],
          ),
        );
      },
    );
  }

  void _tryLogin(BuildContext context, String email, String password) async {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    bool userExists = false; // Replace with actual logic to check user existence
    if (!userExists) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('User not found'),
          content: Text('It seems like you do not have an account. Please sign up first.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(ctx).pop(); // Close the dialog
              },
            ),
          ],
        ),
      );
    } else {
      // Log the user into the system
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Welcome to Kidspot',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              child: Text('Login as Parent'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginForm(role: 'parent'))),
              style: ElevatedButton.styleFrom(primary: Colors.blue),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              child: Text('Login as Child'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginForm(role: 'child'))),
              style: ElevatedButton.styleFrom(primary: Colors.green),
            ),
            SizedBox(height: 40),
            InkWell(
              child: Text(
                "Don't have an account? Sign up",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
              ),
              onTap: () => _showSignUpOptions(context),
            ),
          ],
        ),
      ),
    );
  }
}