import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../commonPages/root_page.dart';

class VerifyEmailPage extends StatefulWidget {
  final UserCredential userCredential;

  const VerifyEmailPage({Key? key, required this.userCredential})
      : super(key: key);

  @override
  VerifyEmailPageState createState() => VerifyEmailPageState();
}

class VerifyEmailPageState extends State<VerifyEmailPage> {
  bool isEmailVerified = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();

    isEmailVerified = widget.userCredential.user!.emailVerified;

    if (!isEmailVerified) {
      sendEmailVerification();

      timer = Timer.periodic(const Duration(seconds: 5), (timer) {
        checkEmailVerified();
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> sendEmailVerification() async {
    try {
      final user = widget.userCredential.user!;
      await user.sendEmailVerification();
    } catch (e) {
      print("An error occurred while trying to send email verification");
    }
  }

Future checkEmailVerified() async {
    User user = FirebaseAuth.instance.currentUser!;
    await user.reload();
    user = FirebaseAuth.instance.currentUser!;
    setState(() {
      isEmailVerified = user.emailVerified;
    });

    if (isEmailVerified) {
      timer?.cancel();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RootPage(),
        ),
      );
    }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Email"),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Center(
                child: Text(
                    "An email has been sent to you. \n Once you verify your email, you will automatically be logged in.")),
            const SizedBox(height: 20),
            isEmailVerified
                ? ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => RootPage(),
                        ),
                      );
                    },
                    child: const Text("Proceed to Home"),
                  )
                : ElevatedButton(
                    onPressed: () {
                      sendEmailVerification();
                    },
                    child: const Text("Resend Email"),
                  ),
          ],
        ),
      ),
    );
  }
}
