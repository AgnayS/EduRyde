import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduryde/components/top_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../components/past_ryde_card.dart';
import '../dataAbstraction/EUser.dart';
import '../dataAbstraction/Rides.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduryde/components/top_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../components/past_ryde_card.dart';
import '../dataAbstraction/EUser.dart';
import '../dataAbstraction/Rides.dart';

class PastRides extends StatelessWidget {
  const PastRides({Key? key}) : super(key: key);

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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.data() == null) {
          return const Center(child: Text('No data available.'));
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
                        text: 'Completed Rydes',
                      ),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('Rides')
                          .where('riderIds', arrayContains: currentUserEmail)
                          .snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data == null) {
                          return const Center(
                              child: Text('No data available.'));
                        }

                        // Here we filter the documents by tripStatus
                        List<QueryDocumentSnapshot> rideDocs = snapshot
                            .data!.docs
                            .where((doc) =>
                                doc.data() != null &&
                                doc['tripStatus'] == 'Completed')
                            .toList();

                        return Column(
                          children:
                              rideDocs.map((QueryDocumentSnapshot document) {
                            Map<String, dynamic> data =
                                document.data() as Map<String, dynamic>;
                            Ride ride = Ride.fromMap(data, document.id);
                            return CompletedRideCard(ride: ride);
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
