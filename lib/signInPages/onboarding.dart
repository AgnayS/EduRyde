import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../dataAbstraction/EUser.dart';
import 'package:eduryde/components/my_button.dart';
import 'package:eduryde/components/my_text_field.dart';
import 'package:eduryde/commonPages/root_page.dart';

class OnboardingPage extends StatefulWidget {
  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final paypalIdController = TextEditingController();
  final venmoIdController = TextEditingController();
  final instagramIdController = TextEditingController();
  final snapchatIdController = TextEditingController();

  String gender = 'Male';
  bool hasCar = false;
  bool isDriver = false;

  void completeOnboarding() async {
    // getting current user's email
    String? userEmail = FirebaseAuth.instance.currentUser!.email;

    if (userEmail == null) {
      showErrorDialog("Error", "User is not logged in.");
      return;
    }

    if (firstNameController.text.isEmpty) {
      showErrorDialog("Error", "First name is required.");
      return;
    }

    if (lastNameController.text.isEmpty) {
      showErrorDialog("Error", "Last name is required.");
      return;
    }

    if (paypalIdController.text.isEmpty && venmoIdController.text.isEmpty) {
      showErrorDialog("Error", "Either Paypal ID or Venmo ID is required.");
      return;
    }

    if (instagramIdController.text.isEmpty &&
        snapchatIdController.text.isEmpty) {
      showErrorDialog(
          "Error", "Either Instagram ID or Snapchat ID is required.");
      return;
    }

    var user = EUser(
      authUid: FirebaseAuth.instance.currentUser!.uid,
      firstName: firstNameController.text,
      lastName: lastNameController.text,
      gender: gender,
      paypalId: paypalIdController.text,
      venmoId: venmoIdController.text,
      hasActiveRide: false,
      hasCar: hasCar,
      isDriver: isDriver,
      isOnboarded: true,
      instagramId: instagramIdController.text,
      snapchatId: snapchatIdController.text,
      driveUids: [],
      rideUids: [], 
    );

    // pushing to Firebase
    pushToFirebase(user, userEmail);

    // Navigate to RootPage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const RootPage()),
    );
  }

  void showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 50),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: const Image(
                    image: AssetImage('lib/images/eduryde_circular.png'),
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  "Let's get you setup!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 25),
                MyTextField(
                  controller: firstNameController,
                  hintText: "First Name",
                  obscureText: false,
                ),
                const SizedBox(height: 10),
                MyTextField(
                  controller: lastNameController,
                  hintText: "Last Name",
                  obscureText: false,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(5)),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      underline: const SizedBox(), // remove the underline
                      value: gender,
                      items: <String>['Male', 'Female', 'Other']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          gender = newValue!;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                MyTextField(
                  controller: paypalIdController,
                  hintText: "Paypal ID",
                  obscureText: false,
                ),
                const SizedBox(height: 10),
                MyTextField(
                  controller: venmoIdController,
                  hintText: "Venmo ID",
                  obscureText: false,
                ),
                const SizedBox(height: 10),
                MyTextField(
                  controller: instagramIdController,
                  hintText: "Instagram ID",
                  obscureText: false,
                ),
                const SizedBox(height: 10),
                MyTextField(
                  controller: snapchatIdController,
                  hintText: "Snapchat ID",
                  obscureText: false,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: CheckboxListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 11), 
                      title: Text(
                        "Do you have a car?",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                        ),
                      ),
                      value: hasCar,
                      onChanged: (bool? value) {
                        setState(() {
                          hasCar = value!;
                          isDriver  = value;
                        });
                      },
                      controlAffinity: ListTileControlAffinity
                          .trailing, // move checkbox to the end
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                MyButton(
                  onTap: completeOnboarding,
                  text: 'Complete Onboarding',
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
