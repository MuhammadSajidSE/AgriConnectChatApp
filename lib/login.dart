import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:newchatapp/contact.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child("users");

  void _login() async {
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter both name and phone number")),
      );
      return;
    }

    DatabaseEvent event = await _dbRef.child(phone).once();
    DataSnapshot snapshot = event.snapshot;

    if (!snapshot.exists) {
      // If user does not exist, create a new one
      await _dbRef.child(phone).set({
        "name": name,
        "phone": phone,
      });
    }

    // Save login state using SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("phone", phone);
    await prefs.setString("name", name);

    // Navigate to contacts screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ContactsScreen(phone: phone)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Login", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Enter your name"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: "Enter your phone number"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
