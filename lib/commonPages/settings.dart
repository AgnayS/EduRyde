import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../signInPages/auth_page.dart';

class SettingsPage extends StatefulWidget {
  final ValueChanged<bool> onModeChanged;
  final ValueChanged<bool> onCarOwnershipChanged;

  SettingsPage(
      {super.key,
      required this.onModeChanged,
      required this.onCarOwnershipChanged});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDriver = false;
  bool hasCar = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        // Not logged in
      } else {
        // User is logged in. Fetch their data
        fetchUser();
      }
    });
  }

  Future<void> fetchUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.email)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          isDriver = docSnapshot.get('isDriver');
          hasCar = docSnapshot.get('hasCar');
          isLoading = false;
        });
      }
    }
  }

  Future<void> signUserOut() async {
    await FirebaseAuth.instance.signOut();
    // ignore: use_build_context_synchronously
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const AuthPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
          child:
              CircularProgressIndicator()); // or some other loading indicator
    } else {
      return Scaffold(
        backgroundColor: Colors.grey.shade300,
        body: ListView(
          children: <Widget>[
            SwitchListTile(
              title: const Text("Do you want to drive?"),
              value: isDriver,
              onChanged: (bool newValue) {
                setState(() {
                  isDriver = newValue;
                });

                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  FirebaseFirestore.instance
                      .collection('Users')
                      .doc(user.email)
                      .update({'isDriver': newValue}).then((_) {
                    widget.onModeChanged(!newValue);
                  });
                }
              },
            ),
            SwitchListTile(
              title: const Text('Do you own a car?'),
              value: hasCar,
              onChanged: (bool newValue) {
                setState(() {
                  hasCar = newValue;
                });

                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  FirebaseFirestore.instance
                      .collection('Users')
                      .doc(user.email)
                      .update({'hasCar': newValue}).then((_) {
                    widget.onCarOwnershipChanged(
                        newValue); // call the callback after update is done
                  });
                }
              },
            ),
            ListTile(
              title: const Text('Sign Out'),
              trailing: IconButton(
                icon: Icon(Icons.logout, color: Theme.of(context).primaryColor),
                onPressed: () async {
                  await signUserOut();
                },
              ),
            ),
          ],
        ),
      );
    }
  }
}
