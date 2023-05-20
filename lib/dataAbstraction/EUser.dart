import 'package:cloud_firestore/cloud_firestore.dart';


class EUser {
  String authUid; // New field
  String firstName;
  String lastName;
  String gender;
  String paypalId;
  String venmoId;
  bool hasActiveRide;
  bool hasCar;
  bool isDriver;
  bool isOnboarded;
  String instagramId;
  String snapchatId;
  List<String> driveUids;
  List<String> rideUids;

  EUser({
    required this.authUid, // New field
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.paypalId,
    required this.venmoId,
    required this.hasActiveRide,
    required this.hasCar,
    required this.isDriver,
    required this.isOnboarded,
    required this.instagramId,
    required this.snapchatId,
    required this.driveUids,
    required this.rideUids,
  });

  // Method to convert a User object into a Map
  Map<String, dynamic> toMap() {
    return {
      'authUid': authUid, // New field
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'paypalId': paypalId,
      'venmoId': venmoId,
      'hasActiveRide': hasActiveRide,
      'hasCar': hasCar,
      'isDriver': isDriver,
      'isOnboarded': isOnboarded,
      'instagramId': instagramId,
      'snapchatId': snapchatId,
      'driveUids': driveUids,
      'rideUids': rideUids,
    };
  }

  // Method to convert a Map into a User object
  factory EUser.fromMap(Map<String, dynamic> map) {
    return EUser(
      authUid: map['authUid'], // New field
      firstName: map['firstName'],
      lastName: map['lastName'],
      gender: map['gender'],
      paypalId: map['paypalId'],
      venmoId: map['venmoId'],
      hasActiveRide: map['hasActiveRide'],
      hasCar: map['hasCar'],
      isDriver: map['isDriver'],
      isOnboarded: map['isOnboarded'],
      instagramId: map['instagramId'],
      snapchatId: map['snapchatId'],
      driveUids: List<String>.from(map['driveUids']),
      rideUids: List<String>.from(map['rideUids']),
    );
  }
}

void pushToFirebase(EUser user, String email) {
  FirebaseFirestore.instance
      .collection('Users')
      .doc(email)
      .set(user.toMap())
      .then((value) {
    print("User added with ID: $email");
  }).catchError((e) {
    print("Error adding user: $e");
  });
}
