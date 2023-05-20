import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:eduryde/signInPages/login_page.dart';
import 'package:eduryde/components/my_button.dart';

class VerifyEmailPage extends StatefulWidget {
  final User user;

  const VerifyEmailPage({Key? key, required this.user}) : super(key: key);

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _isEmailVerified = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    resendVerificationEmail();
    checkEmailVerified();
  }

  checkEmailVerified() async {
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      // reload user data
      await widget.user.reload();
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        timer.cancel();

        setState(() {
          _isEmailVerified = true;
          _isLoading = false;
        });

        // delay navigation for 2 seconds
        await Future.delayed(const Duration(seconds: 2));

        // sign out the user before pushing to login page
        await FirebaseAuth.instance.signOut();

        // ignore: use_build_context_synchronously
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(onTap: () {}),
          ),
        );
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  resendVerificationEmail() async {
    setState(() {
      _isLoading = true;
    });
    await widget.user.sendEmailVerification();
    checkEmailVerified();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                const SizedBox(
                  height: 50,
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: const Image(
                    image: AssetImage('lib/images/eduryde_circular.png'),
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(
                  height: 25,
                ),
                _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      )
                    : (_isEmailVerified
                        ? const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 50,
                          )
                        : Text(
                            "Email not verified",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 18,
                            ),
                          )),
                const SizedBox(
                  height: 25,
                ),
                MyButton(
                  onTap: resendVerificationEmail,
                  text: 'Resend Verification Email',
                ),
                const SizedBox(height: 25),
                MyButton(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  text: 'Change Registration Details',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
