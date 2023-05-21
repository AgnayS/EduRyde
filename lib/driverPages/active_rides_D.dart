import 'dart:async';
import 'package:eduryde/private/api_keys.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import '../dataAbstraction/EUser.dart';
import '../dataAbstraction/Rides.dart';

class ActiveRidesD extends StatefulWidget {
  const ActiveRidesD({Key? key}) : super(key: key);

  @override
  ActiveRidesDState createState() => ActiveRidesDState();
}

class ActiveRidesDState extends State<ActiveRidesD> {
  final Completer<GoogleMapController> _controller = Completer();
  static LatLng? pickupLocation;
  static LatLng? destination;
  LocationData? currentLocation;
  String API_KEY = MAPS_API_KEY;
  bool _mapRendered = false;
  List<LatLng> polylineCoordinates = [];
  String? tripStatus;
  Set<Marker> staticMarkers = {};
  ValueNotifier<Marker?> dynamicMarker = ValueNotifier(null);
  Set<Polyline> _polylines = {};

  EUser? user;
  Ride? activeRide;

  void getPolyPoints(LatLng startLocation, LatLng endLocation) async {
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result;

    result = await polylinePoints.getRouteBetweenCoordinates(
      API_KEY,
      PointLatLng(startLocation.latitude, startLocation.longitude),
      PointLatLng(endLocation.latitude, endLocation.longitude),
    );

    if (result.points.isNotEmpty) {
      polylineCoordinates.clear();
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });

      Polyline polyline = Polyline(
        polylineId: const PolylineId("poly"),
        color: const Color.fromARGB(255, 40, 122, 198),
        points: polylineCoordinates,
      );

      setState(() {
        _polylines.add(polyline);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserData().then(
      (value) {
        if (user!.hasActiveDrive) {
          getCurrentLocation();
          getRideDetails(); // Add this.
          Future.delayed(
            const Duration(seconds: 5),
            () {
              setState(() {
                _mapRendered = true;
              });
            },
          );
        }
      },
    );
  }

  Future<void> fetchUserData() async {
    String? currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    if (currentUserEmail != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUserEmail)
          .get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        user = EUser.fromMap(userData);
      }
    }
  }

  Future<void> getRideDetails() async {
    String? currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    if (currentUserEmail != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUserEmail)
          .get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        user = EUser.fromMap(userData);
        if (user!.activeDriveUid.isNotEmpty) {
          DocumentSnapshot rideDoc = await FirebaseFirestore.instance
              .collection('Rides')
              .doc(user!.activeDriveUid)
              .get();
          if (rideDoc.exists) {
            Map<String, dynamic> rideData =
                rideDoc.data() as Map<String, dynamic>;
            activeRide = Ride.fromMap(rideData, rideDoc.id);
            setState(() {});
          }
        }
      }
    }
  }

  getCurrentLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    currentLocation = await location.getLocation();

    GoogleMapController googleMapController = await _controller.future;

    // Move the camera to the current location once
    googleMapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          zoom: 13.5,
          target: LatLng(
            currentLocation!.latitude!,
            currentLocation!.longitude!,
          ),
        ),
      ),
    );

    location.onLocationChanged.listen((newLoc) {
      currentLocation = newLoc;
      setState(() {});
    });
  }

  void _updateStaticMarkers() {
    staticMarkers.clear();

    if (pickupLocation != null) {
      staticMarkers.add(
        Marker(
          markerId: const MarkerId('pickupLocation'),
          position: pickupLocation!,
        ),
      );
    }

    if (destination != null) {
      staticMarkers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: destination!,
        ),
      );
    }
  }

  

  void startOrCompleteRide(String rideId, String status) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    // Update ride status
    DocumentReference rideRef = firestore.collection('Rides').doc(rideId);
    await rideRef.update({
      'tripStatus': status,
    });

    fetchUserData().then((value) {
      if (user!.hasActiveDrive) {
        getCurrentLocation();
        getRideDetails();
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            _mapRendered = true;
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_mapRendered) {
      return Container(
        color: Colors.grey.shade500.withOpacity(0.8),
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: const Center(
          child: Text(
            'Please accept a ride \n (or wait for the map to load) ',
            style: TextStyle(fontSize: 24, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SlidingUpPanel(
      maxHeight: MediaQuery.of(context).size.height * 0.42,
      minHeight: 40,
      panelBuilder: (scrollController) =>
          buildSlidingPanel(scrollController: scrollController),
      body: Stack(
        children: [
          Column(
            children: <Widget>[
              Expanded(
                child: currentLocation != null && _mapRendered
                    ? CustomGoogleMap(
                        controller: _controller,
                        currentLocation: currentLocation,
                        polylines: _polylines,
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
              SizedBox(
                height: 80,
                child: RidesStreamBuilder(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSlidingPanel({required ScrollController scrollController}) {
    String? currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    if (currentUserEmail == null) {
      return const Center(child: Text('No user logged in.'));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade200,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 20.0,
            color: Colors.grey,
          ),
        ],
      ),
      child: Column(
        children: [
          const Center(
            child: Text(
              "Ride Details",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text("Pickup: ${activeRide!.pickupLocation}"),
                ),
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text("Destination: ${activeRide!.destination}"),
                ),
                ListTile(
                  leading: const Icon(Icons.timer),
                  title: Text("Departure: ${activeRide!.departureTime}"),
                ),
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: Text("Fare: ${activeRide!.fare}"),
                ),
                ElevatedButton(
                  onPressed: () {
                    cancelRide(activeRide!.id);
                  },
                  child: const Text('Cancel Ride'),
                ),
                if (activeRide!.tripStatus == "Accepted")
                  ElevatedButton.icon(
                    onPressed: () {
                      startRide(activeRide!.id);
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Ride'),
                  ),
                if (activeRide!.tripStatus == "InProgress")
                  ElevatedButton.icon(
                    onPressed: () {
                      completeRide(activeRide!.id);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Complete Ride'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void startRide(String rideId) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Update tripStatus to 'InProgress'
    DocumentReference rideRef = firestore.collection('Rides').doc(rideId);
    await rideRef.update({
      'tripStatus': 'InProgress',
    });

    // Refresh UI
    fetchUserData().then((value) {
      if (user!.hasActiveDrive) {
        getCurrentLocation();
        getRideDetails();
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            _mapRendered = true;
          });
        });
      }
    });
  }

  void completeRide(String rideId) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Fetch ride details
    DocumentReference rideRef = firestore.collection('Rides').doc(rideId);
    DocumentSnapshot rideDoc = await rideRef.get();
    Map<String, dynamic> rideData = rideDoc.data() as Map<String, dynamic>;

    List<String> riderIds =
        List<String>.from(rideData['riderIds'] as List<dynamic>);
    String driverId =
        rideData['driverId'] as String; // Fetch the driver's userId

    // Set hasActiveRide to false for all riders and empty activeRideUid
    for (String userId in riderIds) {
      DocumentReference userRef = firestore.collection('Users').doc(userId);
      await userRef.update({
        'hasActiveRide': false,
        'activeRideUid': "",
      });
    }

    // Set hasActiveDrive to false for the driver and empty activeDriveUid
    DocumentReference driverRef = firestore.collection('Users').doc(driverId);
    await driverRef.update({
      'hasActiveDrive': false,
      'activeDriveUid': "",
    });

    // Update tripStatus to 'Completed'
    await rideRef.update({
      'tripStatus': 'Completed',
    });

    setState(() {
      _mapRendered = false;
    });

    // Refresh UI
    fetchUserData().then((value) {
      if (user!.hasActiveDrive) {
        getCurrentLocation();
        getRideDetails();
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            _mapRendered = true;
          });
        });
      }
    });
  }

  void cancelRide(String rideId) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Fetch ride details
    DocumentReference rideRef = firestore.collection('Rides').doc(rideId);
    DocumentSnapshot rideDoc = await rideRef.get();
    Map<String, dynamic> rideData = rideDoc.data() as Map<String, dynamic>;
    Ride ride = Ride.fromMap(rideData, rideDoc.id);

    List<String> riderIds =
        List<String>.from(rideData['riderIds'] as List<dynamic>);
    String driverId =
        rideData['driverId'] as String; // Fetch the driver's userId


    DocumentReference driverRef = firestore.collection('Users').doc(ride.driverId);
    await driverRef.update({
      'hasActiveDrive': false,
      'activeDriveUid': "",
    });

    // Set hasActiveRide to false for all riders and empty activeRideUid
    for (String userId in riderIds) {
      DocumentReference userRef = firestore.collection('Users').doc(userId);
      await userRef.update({
        'hasActiveRide': false,
        'activeRideUid': "",
      });
    }
    rideRef.delete();

    // Set hasActiveDrive to false for the driver and empty activeDriveUid

    // Now reset the map rendered flag so the overlay is shown
    setState(() {
      _mapRendered = false;
    });

    fetchUserData().then((value) {
      if (user!.hasActiveDrive) {
        getCurrentLocation();
        getRideDetails();
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            _mapRendered = true;
          });
        });
      }
    });
  }

  void leaveTrip(String rideId) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    User? currentUser = FirebaseAuth.instance.currentUser;
    String? currentUserEmail = currentUser?.email;

    if (currentUser != null) {
      // Remove current user from ride's rider list
      DocumentReference rideRef = firestore.collection('Rides').doc(rideId);

      // Get current ride data
      DocumentSnapshot rideDoc = await rideRef.get();
      Map<String, dynamic> rideData = rideDoc.data() as Map<String, dynamic>;
      List<String> riderIds =
          List<String>.from(rideData['riderIds'] as List<dynamic>);

      // Remove current user from list
      riderIds.remove(currentUser.uid);

      // Update ride's rider list
      await rideRef.update({
        'riderIds': riderIds,
      });

      // Update tripStatus to 'Pending' if no riders left, else keep it 'Accepted'
      if (riderIds.isEmpty) {
        await rideRef.update({
          'tripStatus': 'Pending',
        });
      }

      DocumentReference userRef =
          firestore.collection('Users').doc(currentUserEmail);
      await userRef.update({
        'hasActiveRide': false,
        'activeRideUid': "",
      });

      // Now reset the map rendered flag so the overlay is shown
      setState(() {
        _mapRendered = false;
      });

      // After leaving the trip, refetch user data and update the state
      fetchUserData().then(
        (value) {
          if (user!.hasActiveRide) {
            getCurrentLocation();
            getRideDetails();
            Future.delayed(
              const Duration(seconds: 2),
              () {
                setState(() {
                  _mapRendered = true;
                });
              },
            );
          }
        },
      );
    }
  }
}

class RidesStreamBuilder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ActiveRidesDState activeRidesDState =
        context.findAncestorStateOfType<ActiveRidesDState>()!;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Rides')
          .where('tripStatus', whereIn: ['Accepted', 'InProgress']).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        }

        if (snapshot.data != null) {
          var rideDoc = snapshot.data!.docs.first;
          Map<String, dynamic> data = rideDoc.data() as Map<String, dynamic>;
          Ride ride = Ride.fromMap(data, rideDoc.id);

          ActiveRidesDState.pickupLocation =
              LatLng(ride.pickupLatLng!.lat, ride.pickupLatLng!.lng);
          ActiveRidesDState.destination =
              LatLng(ride.destinationLatLng!.lat, ride.destinationLatLng!.lng);

          // Update the route based on the trip status
          if (ride.tripStatus == "Accepted") {
            activeRidesDState.getPolyPoints(
              LatLng(activeRidesDState.currentLocation!.latitude!,
                  activeRidesDState.currentLocation!.longitude!),
              ActiveRidesDState.pickupLocation!,
            );
          } else if (ride.tripStatus == "InProgress") {
            activeRidesDState.getPolyPoints(
              LatLng(activeRidesDState.currentLocation!.latitude!,
                  activeRidesDState.currentLocation!.longitude!),
              ActiveRidesDState.destination!,
            );
          }
        }
        return Container();
      },
    );
  }
}

class CustomGoogleMap extends StatelessWidget {
  final Completer<GoogleMapController> controller;
  final LocationData? currentLocation;
  final Set<Polyline> polylines;

  const CustomGoogleMap({
    super.key,
    required this.controller,
    required this.currentLocation,
    required this.polylines,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: (mapController) {
        controller.complete(mapController);
      },
      initialCameraPosition: CameraPosition(
        target: LatLng(
          currentLocation!.latitude!,
          currentLocation!.longitude!,
        ),
        zoom: 13.5,
      ),
      markers: {
        if (ActiveRidesDState.pickupLocation != null)
          Marker(
            markerId: const MarkerId('pickupLocation'),
            position: ActiveRidesDState.pickupLocation!,
            infoWindow: const InfoWindow(title: "Pickup"),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange), // Change marker color to blue
          ),
        if (currentLocation != null)
          Marker(
            markerId: const MarkerId('currentLocation'),
            position:
                LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
            infoWindow: const InfoWindow(title: "You"),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure), // Change marker color to gray
          ),
        if (ActiveRidesDState.destination != null)
          Marker(
            markerId: const MarkerId('destination'),
            position: ActiveRidesDState.destination!,
            infoWindow: const InfoWindow(title: "Dropoff"),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed), // Change marker color to red
          ),
      },
      polylines: polylines,
    );
  }
}
