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
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Sign Up',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: Icon(Icons.g_mobiledata, color: Colors.white),
                  label: Text('Sign in with Google', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    Navigator.pop(context);
                    signInWithGoogle(context);
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue.shade800,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                SizedBox(height: 16), // Consistent spacing
                ElevatedButton.icon(
                  icon: Icon(Icons.email, color: Colors.white),
                  label: Text('Sign up manually', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignUpPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.green.shade500,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.white,
            ],
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
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
            _buildLoginButton(
              label: 'Login as Parent',
              color: Colors.indigo.shade500,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginForm(role: 'parent'))),
            ),
            SizedBox(height: 20),
            _buildLoginButton(
              label: 'Login as Child',
              color: Colors.lightBlue.shade500,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginForm(role: 'child'))),
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

  Widget _buildLoginButton({required String label, required Color color, required VoidCallback onPressed}) {
    return ElevatedButton(
      child: Text(label, style: TextStyle(fontSize: 18, color: Colors.white)),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        primary: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}