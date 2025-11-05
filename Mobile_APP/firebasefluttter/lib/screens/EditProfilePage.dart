import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileEditPage extends StatefulWidget {
  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late TextEditingController _usernameController;
  late TextEditingController _phoneNumberController;
  File? _selectedImage;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _fetchUserData();  // Fetch user data when page is loaded
  }

  // Fetch user data including the image URL from Firestore
  void _fetchUserData() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    var userData = userDoc.data() as Map<String, dynamic>;
    setState(() {
      _currentImageUrl = userData['image_url'];  // Set the current image URL
      _usernameController.text = userData['username'] ?? '';
      _phoneNumberController.text = userData['phone_number'] ?? '';
    });
  }

  // Pick an image either from gallery or camera
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    // Show a dialog with two options: Camera or Gallery
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Select Image Source"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: Text("Camera"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: Text("Gallery"),
          ),
        ],
      ),
    );

    if (source != null) {
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image Section
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _currentImageUrl != null
                        ? CircleAvatar(
                      backgroundImage: NetworkImage(_currentImageUrl!),
                      radius: 50,
                    )
                        : CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      radius: 50,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    // Button to let user choose between camera or gallery
                    IconButton(
                      icon: Icon(Icons.edit, color: Color.fromRGBO(183, 28, 28, 1)),
                      onPressed: _pickImage, // Open the image picker dialog
                    ),
                  ],
                ),
              ),

              // Username Field
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'User Name',
                ),
              ),
              SizedBox(height: 16.0),

              // Phone Number Field
              TextFormField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                ),
              ),
              SizedBox(height: 16.0),

              // Save Button
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    String? imageUrl;
                    if (_selectedImage != null) {
                      // Upload the new image to Firebase Storage
                      final storageRef = FirebaseStorage.instance
                          .ref()
                          .child('user_images')
                          .child('${FirebaseAuth.instance.currentUser!.uid}.jpg');
                      await storageRef.putFile(_selectedImage!);
                      imageUrl = await storageRef.getDownloadURL();
                    } else {
                      imageUrl = _currentImageUrl;  // Keep the old image URL if no new image is picked
                    }

                    // Update Firestore with the new data
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .update({
                      'image_url': imageUrl,
                      'username': _usernameController.text,
                      'phone_number': _phoneNumberController.text,
                    });

                    // Navigate back to the previous screen
                    Navigator.pop(context);
                  },
                  child: Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
