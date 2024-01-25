import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  String _selectedRole = 'Parent';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.reference().child('users');
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _name, _email, _password;
  bool _obscureText = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _trySubmitForm() async {
    final isValid = _formKey.currentState?.validate();
    if (isValid == true) {
      _formKey.currentState?.save();
      String email = emailController.text.trim();
      String password = passwordController.text.trim();

      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (userCredential.user != null) {
          // Get the FCM token
          String fcmToken = await _firebaseMessaging.getToken() ?? '';

          // Associate the FCM token with the user (store it in your backend)
          // Insert user data into the Firebase Realtime Database
          await _database.child(userCredential.user!.uid).set({
            'email': email,
            'name': nameController.text.trim(),
            'phone': phoneController.text.trim(),
            'role': _selectedRole,
            'fcmToken': fcmToken,
          });

          // Successfully signed up, you can add further actions here
          print('Sign-up successful! User ID: ${userCredential.user!.uid}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account successfully registered'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(context);

        } else {
          print('User is null.');
        }
      } catch (e) {
        print('Sign-up Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }

      // Delay the pop to allow the user to see the message
      await Future.delayed(Duration(seconds: 2));

      // Go back to the login page
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextFormField(
                  key: ValueKey('name'),
                  controller: nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 4) {
                      return 'Please enter at least 4 characters';
                    }
                    return null;
                  },
                  onSaved: (value) => _name = value,
                  decoration: InputDecoration(labelText: 'Full Name'),
                ),
                TextFormField(
                  key: ValueKey('email'),
                  controller: emailController,

                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                  onSaved: (value) => _email = value,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: 'Email Address'),
                ),
                TextFormField(
                  key: ValueKey('password'),
                  controller: passwordController,
                  validator: (value) {
                    if (value == null || value.length < 7) {
                      return 'Password must be at least 7 characters long';
                    }
                    return null;
                  },
                  onSaved: (value) => _password = value,
                  obscureText: _obscureText, // Use a variable to determine if the text should be obscured
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText; // Toggle the value
                        });
                      },
                    ),
                  ),
                ),

                SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  key: ValueKey('role'), // Use a key for identification if needed
                  value: _selectedRole,
                  onChanged: (String? newValue) {
                    // Update the selected role when the user makes a selection
                    setState(() {
                      _selectedRole = newValue ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a role';
                    }
                    return null;
                  },
                  items: [
                    DropdownMenuItem<String>(
                      value: 'Parent',
                      child: Text('Parent'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Child',
                      child: Text('Child'),
                    ),
                    // Add more items as needed
                  ],
                  decoration: InputDecoration(
                    labelText: 'Role',
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  child: Text('Sign Up'),
                  onPressed: _trySubmitForm,
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blueAccent,
                    onPrimary: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
