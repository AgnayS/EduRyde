import 'package:flutter/material.dart';

class TravelCard extends StatefulWidget {
  final String departureTime;
  final String destination;
  final String pickupLocation;
  final double fare;
  final IconData icon;
  final VoidCallback onPressed;

  const TravelCard({
    Key? key,
    required this.departureTime,
    required this.destination,
    required this.pickupLocation,
    required this.fare,
    required this.icon,
    required this.onPressed,
  }) : super(key: key);

  @override
  TravelCardState createState() => TravelCardState();
}

class TravelCardState extends State<TravelCard> {
  bool _isSelected = false;

  late String formattedTime;
  late String period;

  @override
  void initState() {
    super.initState();
    var timeParts = widget.departureTime.split(' ');
    formattedTime = timeParts[0].trim(); // HH:MM
    period = timeParts[1].trim(); // AM/PM
  }

  void _toggleCard() {
    setState(() {
      _isSelected = !_isSelected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCard,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: _isSelected ? Colors.green : Colors.blueGrey.shade300,
        ),
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: _isSelected
            ? Center(
                child: IconButton(
                  icon: Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 48.0,
                  ),
                  onPressed: widget.onPressed,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Changed to center
                    children: [
                      Text(
                        formattedTime,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(period,
                          style: const TextStyle(fontSize: 16, color: Colors.white)),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0,right: 7.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center, // Changed to center
                        children: [
                          Text(
                            widget.destination,
                            style:  TextStyle(fontSize: 18, fontWeight: FontWeight.bold,),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.pickupLocation,
                            style: const TextStyle(fontSize: 17, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center, // Changed to center
                    children: [
                      Text(
                        "\$${widget.fare}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Text("Fare",
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
