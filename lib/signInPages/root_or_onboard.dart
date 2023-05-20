import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../commonPages/root_page.dart';
import '../dataAbstraction/EUser.dart';
import 'onboarding.dart';

class RootOrOnboardPage extends StatefulWidget {
  const RootOrOnboardPage({Key? key}) : super(key: key);

  @override
  RootOrOnboardPageState createState() => RootOrOnboardPageState();
}

class RootOrOnboardPageState extends State<RootOrOnboardPage> {
  late Future<OnboardingStatus> _checkFuture;

  Future<OnboardingStatus> checkOnboardingStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot docSnap = await FirebaseFirestore.instance.collection('Users').doc(user.email).get();
      EUser eUser = EUser.fromMap(docSnap.data() as Map<String, dynamic>);
      return eUser.isOnboarded ? OnboardingStatus.onboarded : OnboardingStatus.notOnboarded;
    }
    throw Exception("No user is currently signed in");
  }

  @override
  void initState() {
    super.initState();
    _checkFuture = checkOnboardingStatus();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OnboardingStatus>(
      future: _checkFuture,
      builder: (BuildContext context, AsyncSnapshot<OnboardingStatus> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          switch (snapshot.data) {
            case OnboardingStatus.onboarded:
              return const RootPage();
            case OnboardingStatus.notOnboarded:
            default:
              return OnboardingPage();  // Replace this with your OnboardingPage
          }
        }
      },
    );
  }
}

enum OnboardingStatus { onboarded, notOnboarded }
