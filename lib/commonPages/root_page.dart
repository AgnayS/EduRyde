import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduryde/commonPages/past_rides.dart';
import 'package:eduryde/commonPages/settings.dart';
import 'package:eduryde/driverPages/add_rides_D.dart';
import 'package:eduryde/riderPages/search_rides_R.dart';
import 'package:eduryde/commonPages/active_rides.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../dataAbstraction/EUser.dart';

class RootPage extends StatefulWidget {
  const RootPage({Key? key}) : super(key: key);

  Future<void> signUserOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int currentPage = 0;
  late List<Widget> riderPages;
  late List<Widget> driverPages;
  ValueNotifier<bool> isDriverState = ValueNotifier(true);

  List<Widget> get pages => isDriverState.value ? riderPages : driverPages;

  void fetchUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.email)
          .get();

      if (docSnapshot.exists) {
        EUser euser = EUser.fromMap(docSnapshot.data() as Map<String, dynamic>);
        isDriverState.value = euser.isDriver;
      }
    }
  }

  @override
  void initState() {
    super.initState();

    riderPages = [
      const SearchRidesR(),
      ActiveRides(),
      const PastRides(),
      SettingsPage(
        onModeChanged: (bool isDriver) {
          isDriverState.value = isDriver;
        },
        onCarOwnershipChanged: (bool hasCar) {
          // Handle car ownership changes
        },
      ),
    ];

    driverPages = [
      const AddRidesD(),
      ActiveRides(),
      const PastRides(),
      SettingsPage(
        onModeChanged: (bool isDriver) {
          isDriverState.value = isDriver;
        },
        onCarOwnershipChanged: (bool hasCar) {
          // Handle car ownership changes
        },
      ),
    ];

    fetchUser();
  }

  @override
  void dispose() {
    isDriverState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDriverState,
      builder: (context, value, child) {
        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: SafeArea(
            child: pages[currentPage],
          ),
          bottomNavigationBar: NavigationBar(
            destinations: [
              NavigationDestination(
                icon: isDriverState.value
                    ? const Icon(Icons.search)
                    : const Icon(Icons.add),
                label: isDriverState.value ? "Search" : "Add Rydes",
              ),
              const NavigationDestination(
                icon: Icon(Icons.local_taxi),
                label: "Active Ryde",
              ),
              const NavigationDestination(
                icon: Icon(
                  Icons.history,
                ),
                label: "Past Rydes",
              ),
              const NavigationDestination(
                icon: Icon(
                  Icons.settings,
                ),
                label: "Settings",
              ),
            ],
            onDestinationSelected: (int index) {
              setState(() {
                currentPage = index;
              });
            },
            selectedIndex: currentPage,
          ),
        );
      },
    );
  }
}
