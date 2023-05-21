import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../dataAbstraction/EUser.dart';
import '../dataAbstraction/Rides.dart';

class CompletedRideCard extends StatelessWidget {
  final Ride ride;

  CompletedRideCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('Users')
            .doc(ride.driverId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.data() == null) {
            return const CircularProgressIndicator();
          }

          Map<String, dynamic> data =
              snapshot.data!.data()! as Map<String, dynamic>;
          EUser driver = EUser.fromMap(data);

          return FutureBuilder<List<String>>(
            future: getRiderNames(ride
                .riderIds), // pass the Future returned by getRiderNames to FutureBuilder
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }

              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              return Card(
                color: Colors.blueGrey.shade300, // color change here
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0), // rounder corners30
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0), // increased padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      rowBuilder(
                          'Pickup: ${ride.pickupLocation}', Icons.location_on),
                      SizedBox(height: 8.0), // padding between rows
                      rowBuilder('Destination: ${ride.destination}',
                          Icons.location_on),
                      SizedBox(height: 8.0), // padding between rows
                      rowBuilder(
                          'Driver: ${driver.firstName} ${driver.lastName}',
                          Icons.directions_car),
                      SizedBox(height: 8.0), // padding between rows
                      Column(
                        children: snapshot.data!.map<Widget>((rider) {
                          return rowBuilder(rider, Icons.badge);
                        }).toList(),
                      ),
                      SizedBox(height: 8.0), // padding between rows
                      rowBuilder(
                          'Fare: ${ride.fare.toString()}', Icons.attach_money),
                    ],
                  ),
                ),
              );
            },
          );
        });
  }

Widget rowBuilder(String text, IconData icon) {
  List<String> parts = text.split(':');

  return Row(
    children: <Widget>[
      Icon(icon),
      SizedBox(width: 8),
      Flexible(
        child: RichText(
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(
                text: parts[0] + ':',  // first part in bold
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, color: Colors.black),
              ),
              TextSpan(
                text: parts.length > 1 ? parts[1] : '',  // second part in normal text
                style: TextStyle(fontSize: 16.0, color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}


  Future<List<String>> getRiderNames(List<String> riderIds) async {
    List<String> riderNames = [];
    for (var riderId in riderIds) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(riderId)
          .get();
      Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;
      EUser rider = EUser.fromMap(data);
      riderNames.add('Rider: ${rider.firstName} ${rider.lastName}');
    }
    return riderNames;
  }
}
