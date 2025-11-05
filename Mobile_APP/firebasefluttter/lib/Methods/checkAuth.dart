import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../screens/auth.dart';

class AuthChecker {
  late Timer _timer;

  void startAuthCheck(BuildContext context) {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      checkAuthState(context);
    });
  }

  void stopAuthCheck() {
    _timer.cancel();
  }

  void checkAuthState(BuildContext context) async {
    final _firebase = FirebaseAuth.instance;
    final user = _firebase.currentUser;

    if (user == null) {
      // User is not authenticated, navigate to the login screen
      _firebase.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthScreen()),
      );
      return;
    }

    try {
      // Check if the user is still valid in Firebase Authentication
      await user.reload();
      final currentUser = _firebase.currentUser;

      if (currentUser == null) {
        // User is no longer valid, sign out from the app
        _firebase.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AuthScreen()),
        );
      }
    } catch (e) {
      // An error occurred while checking the user's validity
      print('Error checking user validity: $e');
      // Handle the error as needed
    }
  }
}
