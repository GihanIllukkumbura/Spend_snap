// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class OCRServicePage extends StatelessWidget {
//   final String imageUrl;
//   final String receiptId;
//
//   OCRServicePage({Key? key, required this.imageUrl, required this.receiptId}) : super(key: key);
//
//   Future<Map<String, dynamic>> uploadReceiptUrl(String imageUrl) async {
//     try {
//       var response = await http.post(
//         Uri.parse('http://192.168.8.103:5000/process_receipt_url'), // Change to your computer's IP address
//         body: {'image_url': imageUrl},
//       );
//
//       if (response.statusCode == 200) {
//         return json.decode(response.body);
//       } else {
//         throw Exception("Failed to process the receipt. Status code: ${response.statusCode}");
//       }
//     } catch (e) {
//       throw Exception("Failed to connect to the server: $e");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<Map<String, dynamic>>(
//       future: uploadReceiptUrl(imageUrl),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(child: CircularProgressIndicator());
//         } else if (snapshot.hasError) {
//           return Center(child: Text("Error: ${snapshot.error}"));
//         } else if (!snapshot.hasData) {
//           return Center(child: Text("No data found"));
//         }
//
//         // Here you can display the processed OCR data
//         var data = snapshot.data;
//         return Scaffold(
//           appBar: AppBar(title: Text('OCR Data for Receipt')),
//           body: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               children: <Widget>[
//                 Text("Receipt ID: $receiptId"),
//                 SizedBox(height: 16),
//                 Text("Processed Data:"),
//                 Text("Items: ${data?['items'] ?? 'N/A'}"),
//                 Text("Total: ${data?['total'] ?? 'N/A'}"),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
