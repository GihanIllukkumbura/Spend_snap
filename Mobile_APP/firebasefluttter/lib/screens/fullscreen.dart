import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImagePage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true, // Allow panning
          minScale: 0.5,
          maxScale: 4.0, // Allow zooming
          child: imageUrl.isNotEmpty
              ? Image.network(imageUrl)
              : Icon(
            Icons.receipt,
            size: 100,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
