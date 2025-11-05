import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';  // for formatting date
import 'package:firebase_storage/firebase_storage.dart';
import 'receipt_detail_page.dart';  // Import the new detail page
import 'OCRService.dart';  // Ensure OCRService is properly imported
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReceiptsPage extends StatelessWidget {
  const ReceiptsPage({Key? key}) : super(key: key);

  // Function to delete the receipt from Firestore and Firebase Storage
  Future<void> _deleteReceipt(BuildContext context, String receiptId, String imageUrl) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // User is not authenticated, exit function
      return;
    }

    try {
      // Delete the receipt document from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('receipts')
          .doc(receiptId)
          .delete();

      // If there's an image URL, delete the image from Firebase Storage
      if (imageUrl.isNotEmpty) {
        Reference storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
        await storageRef.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Receipt deleted successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting receipt: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Center(child: Text('You need to log in to see your receipts.'));
    }

    // StreamBuilder to listen for updates on receipts collection in Firestore
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid) // Ensure user is not null
          .collection('receipts')
          .orderBy('timestamp', descending: true) // Order by timestamp (most recent first)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No receipts found.'));
        }

        // Group receipts by month
        Map<String, List<DocumentSnapshot>> groupedReceipts = {};

        for (var doc in snapshot.data!.docs) {
          DateTime timestamp = (doc['timestamp'] as Timestamp).toDate();
          String monthYear = DateFormat('MMMM yyyy').format(timestamp);  // e.g. "December 2024"

          if (!groupedReceipts.containsKey(monthYear)) {
            groupedReceipts[monthYear] = [];
          }

          groupedReceipts[monthYear]!.add(doc);
        }

        return ListView.builder(
          itemCount: groupedReceipts.keys.length,
          itemBuilder: (context, index) {
            String monthYear = groupedReceipts.keys.elementAt(index);
            List<DocumentSnapshot> receiptsForMonth = groupedReceipts[monthYear]!;

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    monthYear,
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: receiptsForMonth.length,
                    itemBuilder: (context, receiptIndex) {
                      var receipt = receiptsForMonth[receiptIndex];
                      DateTime timestamp = (receipt['timestamp'] as Timestamp).toDate();
                      String date = DateFormat('dd MMM yyyy').format(timestamp);
                      String time = DateFormat('hh:mm a').format(timestamp);
                      String imageUrl = receipt['imageUrl'] ?? '';
                      String merchantName = receipt['merchant_name'] ?? 'Unknown Merchant';
                      String amount = receipt['amount'] ?? 'N/A';
                      String receiptId = receipt.id;  // Receipt ID for Firestore

                      return Card(
                        color: Color.fromRGBO(66, 66, 66, 0.7),
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          leading: imageUrl.isNotEmpty
                              ? InkWell(
                            // Inside the onTap handler for the receipt image
                            onTap: () async {
                              final docSnapshot = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('receipts')
                                  .doc(receiptId)
                                  .get();

                              if (docSnapshot.exists) {
                                final data = docSnapshot.data()!;
                                if (data['saved'] == 1) {
                                  // If saved, navigate to ReceiptDetailPage with Firestore data
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReceiptDetailPage(
                                        receiptId: receiptId,
                                        imageUrl: imageUrl,
                                        merchantName: data['merchant_name'] ?? '',
                                        date: data['date'] ?? '',
                                        time: data['time'] ?? '',
                                        amount: data['amount'] ?? '',
                                        items: List<Map<String, dynamic>>.from(data['items'] ?? []),
                                        total: data['total'] ?? 0.0,
                                        isSaved: true,
                                      ),
                                    ),
                                  );
                                } else {
                                  // If not saved, fetch data from the backend
                                  try {
                                    final response = await http.post(
                                      Uri.parse('http://10.0.2.2:5000/parse_receipt'),
                                      headers: {'Content-Type': 'application/json'},
                                      body: json.encode({'image_url': imageUrl}),
                                    );

                                    if (response.statusCode == 200) {
                                      final ocrData = json.decode(response.body);
                                      final items = ocrData['items'] ?? [];
                                      final total = ocrData['total_price'] ?? 0.0;

                                      // Save the data in Firestore
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(user.uid)
                                          .collection('receipts')
                                          .doc(receiptId)
                                          .update({
                                        'items': items,
                                        'total': total,
                                        'saved': 1, // Mark as saved
                                      });

                                      // Navigate to ReceiptDetailPage
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ReceiptDetailPage(
                                            receiptId: receiptId,
                                            imageUrl: imageUrl,
                                            merchantName: merchantName,
                                            date: date,
                                            time: time,
                                            amount: amount,
                                            items: items,
                                            total: total,
                                            isSaved: false,
                                          ),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed to fetch OCR data.')),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              }
                            },



                            child: Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                          )
                              : Icon(Icons.receipt, color: Colors.white),
                          title: Text(merchantName, style: TextStyle(color: Colors.white)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(date, style: TextStyle(color: Colors.white)),
                              Text(time, style: TextStyle(color: Colors.white)),
                              Text(amount, style: TextStyle(color: Colors.white)),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // Show a confirmation dialog
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Delete Receipt'),
                                    content: Text('Are you sure you want to delete this receipt?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(); // Close the dialog
                                        },
                                        child: Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          // Delete the receipt
                                          _deleteReceipt(context, receiptId, imageUrl);
                                          Navigator.of(context).pop(); // Close the dialog
                                        },
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
