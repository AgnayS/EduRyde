import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';

class Ride {
  String id;
  String driverId;
  List<String> riderIds;
  String destination;
  String pickupLocation;
  LatLng? destinationLatLng;
  LatLng? pickupLatLng;
  String departureTime;
  double fare;
  String tripStatus;

  Ride({
    required this.id,
    required this.driverId,
    required this.riderIds,
    required this.destination,
    required this.pickupLocation,
    this.destinationLatLng,
    this.pickupLatLng,
    required this.departureTime,
    required this.fare,
    required this.tripStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'riderIds': riderIds,
      'destination': destination,
      'pickupLocation': pickupLocation,
      'destinationLatLng': {
        'lat': destinationLatLng?.lat,
        'lng': destinationLatLng?.lng,
      },
      'pickupLatLng': {
        'lat': pickupLatLng?.lat,
        'lng': pickupLatLng?.lng,
      },
      'departureTime': departureTime,
      'fare': fare,
      'tripStatus': tripStatus,
    };
  }

  factory Ride.fromMap(Map<String, dynamic> map, String id) {
    LatLng? destinationLatLng;
    LatLng? pickupLatLng;

    if (map['destinationLatLng'] != null) {
  destinationLatLng = LatLng(
    lat: map['destinationLatLng']['lat'],
    lng: map['destinationLatLng']['lng'],
  );
}

if (map['pickupLatLng'] != null) {
  pickupLatLng = LatLng(
    lat: map['pickupLatLng']['lat'],
    lng: map['pickupLatLng']['lng'],
  );
}


    return Ride(
      id: id,
      driverId: map['driverId'],
      riderIds: List<String>.from(map['riderIds']),
      destination: map['destination'],
      pickupLocation: map['pickupLocation'],
      destinationLatLng: destinationLatLng,
      pickupLatLng: pickupLatLng,
      departureTime: map['departureTime'],
      fare: map['fare'].toDouble(),
      tripStatus: map['tripStatus'],
    );
  }
}

void pushRideToFirebase(Ride ride) {
  FirebaseFirestore.instance
      .collection('Rides')
      .add(ride.toMap())
      .then((DocumentReference document) {
    print("Document added with ID: ${document.id}");
  }).catchError((e) {
    print("Error adding document: $e");
  });
}
