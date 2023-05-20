import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';

class AutoCompleteTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? Function(String?) validator;
  final FlutterGooglePlacesSdk places;
  final ValueNotifier<Place?> placeValueNotifier;
  final ValueNotifier<LatLng?> latLngValueNotifier;

  const AutoCompleteTextField({
    Key? key,
    required this.controller,
    required this.labelText,
    required this.validator,
    required this.places,
    required this.placeValueNotifier,
    required this.latLngValueNotifier,
  }) : super(key: key);

  @override
  AutoCompleteTextFieldState createState() => AutoCompleteTextFieldState();
}

class AutoCompleteTextFieldState extends State<AutoCompleteTextField> {
  List<AutocompletePrediction> _predictions = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: widget.labelText,
          ),
          validator: widget.validator,
          onChanged: (value) async {
            if (value.length < 3) {
              setState(() {
                _predictions = [];
              });
              return;
            }

            FindAutocompletePredictionsResponse response =
                await widget.places.findAutocompletePredictions(value);
            setState(() {
              _predictions = response.predictions;
            });
          },
        ),
        if (_predictions.isNotEmpty)
          SizedBox(
            height: 200, 
            child: ListView.builder(
              itemCount: _predictions.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(_predictions[index].primaryText),
                  onTap: () async {
                    FetchPlaceResponse fetchPlaceResponse = await widget.places
                        .fetchPlace(_predictions[index].placeId, fields: [
                      PlaceField.Location,
                      PlaceField.Name
                    ]); 

                    Place? place = fetchPlaceResponse
                        .place; 
                    setState(() {
                      widget.controller.text = place!.name!;
                      widget.placeValueNotifier.value = place;
                      widget.latLngValueNotifier.value = place.latLng;
                      _predictions = [];
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
