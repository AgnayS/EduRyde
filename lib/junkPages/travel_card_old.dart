import 'package:flutter/material.dart';

class TravelCard extends StatelessWidget {
  final TimeOfDay departureTime;
  final String destination;
  final String pickupLocation;
  final VoidCallback onPressed;
  final IconData icon;

  const TravelCard({super.key, 
    required this.departureTime,
    required this.destination,
    required this.pickupLocation,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final period = departureTime.hour >= 12 ? 'PM' : 'AM';
    final hour =
        (departureTime.hour > 12) ? departureTime.hour - 12 : departureTime.hour;
    final formattedTime = '${hour.toString().padLeft(2, '0')}:${departureTime.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.blueGrey.shade300,
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formattedTime,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(period),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                destination,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                pickupLocation,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
          InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                icon,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
