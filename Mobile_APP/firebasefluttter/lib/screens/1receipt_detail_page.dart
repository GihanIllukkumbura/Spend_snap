// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'OCRService.dart';
//
// class ReceiptDetailPage extends StatefulWidget {
//   final String imageUrl;
//   final String date;
//   final String time;
//   final String amount;
//
//   const ReceiptDetailPage({
//     Key? key,
//     required this.imageUrl,
//     required this.date,
//     required this.time,
//     required this.amount,
//   }) : super(key: key);
//
//   @override
//   _ReceiptDetailPageState createState() => _ReceiptDetailPageState();
// }
//
// class _ReceiptDetailPageState extends State<ReceiptDetailPage> {
//   String extractedText = 'Loading...'; // Placeholder text while loading
//
//   @override
//   void initState() {
//     super.initState();
//    // _extractTextFromImage();
//   }
//
//   // Future<void> _extractTextFromImage() async {
//   //   final File imageFile = File(widget.imageUrl);
//   //   final result = await OCRService.getReceiptDetails(imageFile);
//   //
//   //   setState(() {
//   //     // Check if the result has a valid structure and extract text
//   //     extractedText = result != null && result.containsKey('text')
//   //         ? result['text']
//   //         : 'No text found'; // Default message if text is not found
//   //   });
//   // }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Receipt Details'),
//         backgroundColor: const Color.fromRGBO(183, 28, 28, 1),
//       ),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           GestureDetector(
//             onTap: () => _showFullScreenImage(context), // Open full-screen image view
//             child: Container(
//               height: MediaQuery.of(context).size.height / 3,
//               decoration: BoxDecoration(
//                 image: DecorationImage(
//                   image: _getImageProvider(widget.imageUrl), // Get image provider
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 10), // Space between image and text
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text("Date: ${widget.date}", style: const TextStyle(fontSize: 18)),
//                 const SizedBox(height: 5),
//                 Text("Time: ${widget.time}", style: const TextStyle(fontSize: 18)),
//                 const SizedBox(height: 5),
//                 Text("Amount: ${widget.amount}", style: const TextStyle(fontSize: 18)),
//                 const SizedBox(height: 10),
//                 Text("Extracted Text:", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 5),
//                 Text(
//                   extractedText,
//                   style: const TextStyle(fontSize: 16), // Display the OCR text here
//                   textAlign: TextAlign.left,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
// // Helper function to determine which ImageProvider to use
//   ImageProvider<Object> _getImageProvider(String imageUrl) {
//     return imageUrl.startsWith('http')
//         ? NetworkImage(imageUrl) as ImageProvider<Object>
//         : FileImage(File(imageUrl)) as ImageProvider<Object>;
//   }
//
//
//   void _showFullScreenImage(BuildContext context) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (context) => FullScreenImageView(imageUrl: widget.imageUrl),
//       ),
//     );
//   }
// }
//
// class FullScreenImageView extends StatelessWidget {
//   final String imageUrl;
//
//   const FullScreenImageView({Key? key, required this.imageUrl})
//       : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           Image(
//             image: _getImageProvider(imageUrl), // Get image provider
//             fit: BoxFit.cover, // Fill the entire screen
//             width: double.infinity,
//             height: double.infinity,
//           ),
//           Positioned(
//             top: 40,
//             left: 20,
//             child: IconButton(
//               icon: const Icon(Icons.close, color: Colors.white, size: 30),
//               onPressed: () =>
//                   Navigator.of(context).pop(), // Close full-screen view
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Helper function to determine which ImageProvider to use
//   ImageProvider<Object> _getImageProvider(String imageUrl) {
//     return imageUrl.startsWith('http')
//         ? NetworkImage(imageUrl) as ImageProvider<Object>
//         : FileImage(File(imageUrl)) as ImageProvider<Object>;
//   }
// }
//
