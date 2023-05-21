import 'package:eduryde/components/top_text.dart';
import 'package:eduryde/components/travel_card.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
import '../components/auto_complete_text_field.dart';
import '../dataAbstraction/EUser.dart';
import '../dataAbstraction/Rides.dart';
import '../private/api_keys.dart';

class AddRidesD extends StatefulWidget {
  const AddRidesD({super.key});

  @override
  AddRidesDState createState() => AddRidesDState();
}

class AddRidesDState extends State<AddRidesD> {
  static const String API_KEY = MAPS_API_KEY;
  final places = FlutterGooglePlacesSdk(API_KEY); //api_key
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _fareController = TextEditingController();
  ValueNotifier<Place?> _destinationPlaceNotifier = ValueNotifier(null);
  ValueNotifier<LatLng?> _destinationLatLngNotifier = ValueNotifier(null);
  ValueNotifier<Place?> _pickupPlaceNotifier = ValueNotifier(null);
  ValueNotifier<LatLng?> _pickupLatLngNotifier = ValueNotifier(null);

  bool _isFormVisible = false;
  Ride? _editingRide;

  Future<void> _saveRide() async {
    if (_formKey.currentState!.validate()) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        Ride ride = Ride(
          id: '',
          driverId: currentUser.email!,
          riderIds: [],
          destination: _destinationController.text,
          destinationLatLng: _destinationLatLngNotifier.value,
          pickupLocation: _pickupController.text,
          pickupLatLng: _pickupLatLngNotifier.value,
          departureTime: _timeController.text,
          fare: double.parse(_fareController.text),
          tripStatus: 'Pending',
        );
        if (_editingRide != null) {
          FirebaseFirestore.instance
              .collection('Rides')
              .doc(_editingRide!.id)
              .update(ride.toMap())
              .then((_) => print("Ride updated"))
              .catchError((e) => print("Error updating ride: $e"));
        } else {
          pushRideToFirebase(ride);
        }
        _toggleFormVisibility();
      }
    }
  }

  Future<void> _deleteRide() async {
    if (_editingRide != null) {
      FirebaseFirestore.instance
          .collection('Rides')
          .doc(_editingRide!.id)
          .delete()
          .then((_) => print("Ride deleted"))
          .catchError((e) => print("Error deleting ride: $e"));
      _toggleFormVisibility();
    }
  }

  void _toggleFormVisibility({Ride? ride}) {
    setState(() {
      _isFormVisible = !_isFormVisible;
      _editingRide = ride;

      if (ride != null) {
        // Fill the form fields with the ride data
        _timeController.text = ride.departureTime;
        _destinationController.text = ride.destination;
        _pickupController.text = ride.pickupLocation;
        _fareController.text = ride.fare.toString();
      } else {
        // Clear the form fields
        _timeController.clear();
        _destinationController.clear();
        _pickupController.clear();
        _fareController.clear();
      }
    });
  }

  Stream<bool> getDriverStatus() {
    final currentUser = FirebaseAuth.instance.currentUser;
    return FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser?.email)
        .snapshots()
        .map((doc) {
      Map<String, dynamic> driverData = doc.data()! as Map<String, dynamic>;
      EUser driver = EUser.fromMap(driverData);
      return driver.hasActiveDrive;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleFormVisibility,
        backgroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
      body: Stack(
        // <-- Change from Column to Stack here
        children: [
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                child: TopText(
                  text: 'My Rydes',
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('Rides')
                          .where('driverId', isEqualTo: currentUser?.email)
                          .where('tripStatus',
                              isEqualTo: 'Pending') // New condition here
                          .snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasError) {
                          return const Text('Something went wrong');
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }

                        return ListView(
                          children: snapshot.data!.docs
                              .map((DocumentSnapshot document) {
                            Map<String, dynamic> data =
                                document.data()! as Map<String, dynamic>;
                            Ride ride = Ride.fromMap(data, document.id);
                            return TravelCard(
                              departureTime: ride.departureTime,
                              destination: ride.destination,
                              pickupLocation: ride.pickupLocation,
                              onPressed: () =>
                                  _toggleFormVisibility(ride: ride),
                              fare: ride.fare,
                              icon: Icons.edit,
                            );
                          }).toList(),
                        );
                      },
                    ),
                    if (_isFormVisible)
                      Center(
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).canvasColor,
                            borderRadius: BorderRadius.circular(15.0),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 15.0,
                                spreadRadius: 1.0,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize
                                .min, // restrict the Column size to its children's size
                            children: [
                              Flexible(
                                // <-- Wrapped ListView in a Flexible widget
                                child: Form(
                                  key: _formKey,
                                  child: ListView(
                                    shrinkWrap:
                                        true, // restricts the ListView to wrap its content
                                    children: _formFields(),
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _toggleFormVisibility,
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          StreamBuilder<bool>(
            stream: getDriverStatus(),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox
                    .shrink(); // Returns an empty widget while waiting
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                // The overlay widget
                return (snapshot.data! && !_isFormVisible)
                    ? Container(
                        color: Colors.grey.shade500.withOpacity(0.8),
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        child: const Center(
                          child: Text(
                            'Ride Accepted!',
                            style: TextStyle(fontSize: 24, color: Colors.white),
                          ),
                        ),
                      )
                    : const SizedBox
                        .shrink(); // Returns an empty widget if no ride is accepted or the form is visible
              }
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _formFields() {
    return [
      InkWell(
        onTap: () async {
          final TimeOfDay? pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );

          if (pickedTime != null) {
            _timeController.text = pickedTime.format(context);
          }
        },
        child: AbsorbPointer(
          child: TextFormField(
            controller: _timeController,
            decoration: const InputDecoration(
              labelText: 'Time',
            ),
          ),
        ),
      ),
      AutoCompleteTextField(
        controller: _destinationController,
        labelText: 'Destination',
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter destination';
          }
          return null; // return null when the input is valid
        },
        places: places,
        placeValueNotifier: _destinationPlaceNotifier,
        latLngValueNotifier: _destinationLatLngNotifier,
      ),
      AutoCompleteTextField(
        controller: _pickupController,
        labelText: 'Pickup Location',
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter pickup location';
          }
          return null; // return null when the input is valid
        },
        places: places,
        placeValueNotifier: _pickupPlaceNotifier,
        latLngValueNotifier: _pickupLatLngNotifier,
      ),
      TextFormField(
        controller: _fareController,
        decoration: const InputDecoration(
          labelText: 'Fare',
        ),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value!.isEmpty) {
            return 'Please enter fare';
          }
          if (double.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
          return null;
        },
      ),
      ElevatedButton(
        onPressed: _saveRide,
        child: const Text('Save Ride'),
      ),
      if (_editingRide != null)
        ElevatedButton(
          onPressed: _deleteRide,
          child: const Text('Delete Ride'),
        ),
    ];
  }

  Future<List<AutocompletePrediction>?> showAutocompleteDialog(
      BuildContext context, String searchTerm) async {
    if (searchTerm.length < 3) {
      // Don't perform a search if the search term is too short.
      return [];
    }

    FindAutocompletePredictionsResponse response =
        await places.findAutocompletePredictions(searchTerm);
    List<AutocompletePrediction>? predictions = response.predictions;

    if (predictions.isNotEmpty) {
      // If there are any predictions, show them in a dialog
      // ignore: use_build_context_synchronously
      final selectedPrediction = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select a location'),
          content: SingleChildScrollView(
            child: ListBody(
              children: predictions.map((prediction) {
                return ListTile(
                  title: Text(prediction.primaryText),
                  onTap: () {
                    Navigator.of(context).pop(prediction);
                  },
                );
              }).toList(),
            ),
          ),
        ),
      );

      if (selectedPrediction != null) {
        // If a prediction was selected, return it in a list
        return [selectedPrediction];
      }
    }

    return predictions;
  }

  @override
  void dispose() {
    _timeController.dispose();
    _destinationController.dispose();
    _pickupController.dispose();
    _fareController.dispose();
    _destinationPlaceNotifier.dispose();
    _destinationLatLngNotifier.dispose();
    _pickupPlaceNotifier.dispose();
    _pickupLatLngNotifier.dispose();
    super.dispose();
  }
}
