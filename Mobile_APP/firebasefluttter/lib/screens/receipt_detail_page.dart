import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'EditReceiptPage.dart';
import 'fullscreen.dart';

class ReceiptDetailPage extends StatefulWidget {
  final String receiptId;
  final bool isSaved;
  final String imageUrl;
  final String merchantName;
  final String date;
  final String time;
  final String amount;
  final List<Map<String, dynamic>> items;
  final double? total;

  const ReceiptDetailPage({
    Key? key,
    required this.receiptId,
    required this.isSaved,
    required this.imageUrl,
    required this.merchantName,
    required this.date,
    required this.time,
    required this.amount,
    required this.items,
    this.total,
  }) : super(key: key);

  @override
  _ReceiptDetailPageState createState() => _ReceiptDetailPageState();
}

class _ReceiptDetailPageState extends State<ReceiptDetailPage> {
  late String finalCategory;
  late List<Map<String, dynamic>> items;

  @override
  void initState() {
    super.initState();
    items = List<Map<String, dynamic>>.from(widget.items); // Local copy of items
    _calculateFinalCategory();
  }

  void _calculateFinalCategory() {
    if (items.isNotEmpty) {
      final categoryCounts = <String, int>{};
      for (var item in items) {
        final category = item['category'] ?? 'Uncategorized';
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }

      finalCategory = categoryCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    } else {
      finalCategory = 'No Items';
    }
    setState(() {}); // Update UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              final isUpdated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditReceiptPage(
                    receiptId: widget.receiptId,
                    merchantName: widget.merchantName,
                    date: widget.date,
                    time: widget.time,
                    amount: widget.amount,
                    items: items, // Pass the local copy of items
                    total: widget.total,
                  ),
                ),
              );

              if (isUpdated == true) {
                // Re-fetch data or update items after editing
                final receiptDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .collection('receipts')
                    .doc(widget.receiptId)
                    .get();

                if (receiptDoc.exists) {
                  setState(() {
                    items = List<Map<String, dynamic>>.from(
                      receiptDoc.data()?['items'] ?? [],
                    );
                    _calculateFinalCategory();
                  });
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Top half: Receipt Image
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FullScreenImagePage(imageUrl: widget.imageUrl),
                  ),
                );
              },
              child: widget.imageUrl.isNotEmpty
                  ? Image.network(
                widget.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) =>
                    Center(child: Icon(Icons.broken_image, size: 100)),
              )
                  : Center(
                child: Icon(Icons.receipt,
                    size: 100, color: Colors.grey),
              ),
            ),
          ),
          // Bottom half: Receipt Details
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category: $finalCategory',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Merchant Name: ${widget.merchantName.isNotEmpty ? widget.merchantName : 'Unknown'}',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Date: ${widget.date.isNotEmpty ? widget.date : 'N/A'}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Time: ${widget.time.isNotEmpty ? widget.time : 'N/A'}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Items:',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    items.isNotEmpty
                        ? ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final itemName = item['name'] ?? 'Unknown Item';
                        final itemPrice = item['price']
                            ?.toStringAsFixed(2) ??
                            '0.00';
                        final itemCategory =
                            item['category'] ?? 'Uncategorized';
                        return Padding(
                          padding:
                          const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            '$itemName (\$$itemPrice) - Category: $itemCategory',
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      },
                    )
                        : Text(
                      'No items available.',
                      style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey),
                    ),
                    Divider(),
                    Text(
                      'Total: \$${widget.total?.toStringAsFixed(2) ?? 'N/A'}',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
