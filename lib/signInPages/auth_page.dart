import 'package:eduryde/signInPages/login_or_register.dart';
import 'package:eduryde/signInPages/root_or_onboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  AuthPageState createState() => AuthPageState();
}

class AuthPageState extends State<AuthPage> {
  late Future<UserStatus> _checkFuture;

  Future<UserStatus> checkUserStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      return user.emailVerified ? UserStatus.signedInAndVerified : UserStatus.signedInButUnverified;
    }
    return UserStatus.signedOut;
  }

  @override
  void initState() {
    super.initState();
    _checkFuture = checkUserStatus();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserStatus>(
      future: _checkFuture,
      builder: (BuildContext context, AsyncSnapshot<UserStatus> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          switch (snapshot.data) {
            case UserStatus.signedInAndVerified:
              return const RootOrOnboardPage();
            case UserStatus.signedInButUnverified:
            case UserStatus.signedOut:
            default:
              return const LoginOrRegisterPage();
          }
        }
      },
    );
  }
}


enum UserStatus { signedInAndVerified, signedInButUnverified, signedOut }
