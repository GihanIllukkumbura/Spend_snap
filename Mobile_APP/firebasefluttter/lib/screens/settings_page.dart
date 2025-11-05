import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Allows the body to extend behind the AppBar
      appBar: AppBar(
        title: Text("Settings"),
        elevation: 0, // Removes shadow to make it seamless
        backgroundColor: Colors.transparent, // Transparent AppBar for seamless appearance
        toolbarHeight: kToolbarHeight, // Ensure AppBar height is consistent
        iconTheme: IconThemeData(color: Colors.white), // Change icon color to white
      ),
      body: SafeArea( // SafeArea ensures no content goes under the system UI areas
        child: ListView(
          padding: EdgeInsets.zero,  // Removes extra padding around the ListView
          children: [
            // Other settings items can go here

            // Log out ListTile
            ListTile(
              title: Text('Log out'),
              onTap: () async {
                try {
                  // Sign out the user
                  await FirebaseAuth.instance.signOut();

                  // Navigate to the Auth screen (login page)
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => AuthScreen()),
                  );
                } catch (e) {
                  // Handle any errors during sign-out
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
              trailing: Icon(Icons.exit_to_app), // Optional icon
            ),
          ],
        ),
      ),
    );
  }
}
