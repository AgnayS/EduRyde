import 'dart:async';
import 'package:eduryde/private/api_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import '../dataAbstraction/Rides.dart';

class ActiveRides extends StatefulWidget {
  ActiveRides({Key? key}) : super(key: key);

  @override
  ActiveRidesState createState() => ActiveRidesState();
}

class ActiveRidesState extends State<ActiveRides> {
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
    getCurrentLocation();
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _mapRendered = true;
      });
    });
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

  @override
  Widget build(BuildContext context) {
    return SlidingUpPanel(
      maxHeight: MediaQuery.of(context).size.height * 0.5,
      minHeight: 40,
      panelBuilder: (scrollController) =>
          buildSlidingPanel(scrollController: scrollController),
      body: Column(
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
            // or use Container
            height: 80,
            child: RidesStreamBuilder(),
          ),
        ],
      ),
    );
  }

  Widget buildSlidingPanel({required ScrollController scrollController}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade200, // Change color here
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
      child: ListView(
        controller: scrollController,
        children: const <Widget>[
          Center(
            child: Text(
              "Ride Details",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          // Add the widgets that make up your panel content here
        ],
      ),
    );
  }
}

class RidesStreamBuilder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ActiveRidesState activeRidesRState =
        context.findAncestorStateOfType<ActiveRidesState>()!;

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

          ActiveRidesState.pickupLocation =
              LatLng(ride.pickupLatLng!.lat, ride.pickupLatLng!.lng);
          ActiveRidesState.destination =
              LatLng(ride.destinationLatLng!.lat, ride.destinationLatLng!.lng);

          // Update the route based on the trip status
          if (ride.tripStatus == "Accepted") {
            activeRidesRState.getPolyPoints(
              LatLng(activeRidesRState.currentLocation!.latitude!,
                  activeRidesRState.currentLocation!.longitude!),
              ActiveRidesState.pickupLocation!,
            );
          } else if (ride.tripStatus == "InProgress") {
            activeRidesRState.getPolyPoints(
              LatLng(activeRidesRState.currentLocation!.latitude!,
                  activeRidesRState.currentLocation!.longitude!),
              ActiveRidesState.destination!,
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

  CustomGoogleMap({
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
        if (ActiveRidesState.pickupLocation != null)
          Marker(
            markerId: const MarkerId('pickupLocation'),
            position: ActiveRidesState.pickupLocation!,
            infoWindow: const InfoWindow(title: "Pickup"),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange), // Change marker color to blue
          ),
        if (currentLocation != null)
          Marker(
            markerId: const MarkerId('currentLocation'),
            position:
                LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
                infoWindow: const InfoWindow(title: "You"),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), // Change marker color to gray
          ),
        if (ActiveRidesState.destination != null)
          Marker(
            markerId: const MarkerId('destination'),
            position: ActiveRidesState.destination!,
            infoWindow: const InfoWindow(title: "Dropoff"),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), // Change marker color to red
          ),
      },
      polylines: polylines,
    );
  }
}

