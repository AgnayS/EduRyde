import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduryde/components/travel_card.dart';
import 'package:eduryde/components/top_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../components/my_button.dart';
import '../dataAbstraction/EUser.dart';
import '../dataAbstraction/Rides.dart';

class SearchRidesR extends StatelessWidget {
  const SearchRidesR({Key? key}) : super(key: key);

  Future<void> processRide(EUser user, String rideId) async {
    user.hasActiveRide = true;
    user.rideUids.add(rideId);
    user.activeRideUid =
        rideId; // Setting the active ride UID when the ride is accepted
    String? currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    if (currentUserEmail != null) {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUserEmail)
          .update(user.toMap());

      DocumentReference rideRef =
          FirebaseFirestore.instance.collection('Rides').doc(rideId);
      DocumentSnapshot rideDoc = await rideRef.get();

      if (rideDoc.exists) {
        Map<String, dynamic> rideData = rideDoc.data()! as Map<String, dynamic>;
        Ride ride = Ride.fromMap(rideData, rideDoc.id);
        ride.riderIds.add(currentUserEmail); // Using email instead of UID
        ride.tripStatus =
            'Accepted'; // Here we change the tripStatus to 'Accepted'
        await rideRef.update(ride.toMap());

        // Get driver document and update
        DocumentReference driverRef =
            FirebaseFirestore.instance.collection('Users').doc(ride.driverId);
        DocumentSnapshot driverDoc = await driverRef.get();

        if (driverDoc.exists) {
          Map<String, dynamic> driverData =
              driverDoc.data()! as Map<String, dynamic>;
          EUser driver = EUser.fromMap(driverData);

          if (!driver.hasActiveDrive && driver.activeDriveUid.isEmpty) {
            await driverRef.update({
              'hasActiveDrive': true,
              'activeDriveUid': rideId,
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String? currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    if (currentUserEmail == null) {
      return const Center(child: Text('No user logged in.'));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUserEmail)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.data() == null) {
          return const Center(child: CircularProgressIndicator());
        }

        Map<String, dynamic> data =
            snapshot.data!.data()! as Map<String, dynamic>;
        EUser user = EUser.fromMap(data);

        return Stack(
          children: [
            Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              color: Colors.grey.shade300,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                      child: TopText(
                        text: 'Available Rydes',
                      ),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('Rides')
                          .snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasError) {
                          return const Text('Something went wrong');
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text("Loading...");
                        }

                        // Here we filter the documents by tripStatus
                        List<DocumentSnapshot> rideDocs =
                            snapshot.data!.docs.where((doc) {
                          if (doc.data() != null) {
                            var data = doc.data() as Map<String, dynamic>;
                            Ride ride = Ride.fromMap(data, doc.id);
                            return ride.tripStatus != 'Completed';
                          }
                          return false;
                        }).toList();

                        return Column(
                          children: rideDocs.map((DocumentSnapshot document) {
                            Map<String, dynamic> data =
                                document.data()! as Map<String, dynamic>;
                            Ride ride = Ride.fromMap(data, document.id);
                            return TravelCard(
                              departureTime: ride.departureTime,
                              destination: ride.destination,
                              pickupLocation: ride.pickupLocation,
                              onPressed: user.hasActiveRide
                                  ? () {}
                                  : () {
                                      processRide(user, document.id);
                                    },
                              fare: ride.fare,
                              icon: Icons.check,
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (user.hasActiveRide)
              Container(
                color: Colors.grey.shade500.withOpacity(0.8),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: const Center(
                  child: Text(
                    'Ride Selected!',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
