import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditReceiptPage extends StatefulWidget {
  final String receiptId;
  final String merchantName;
  final String date;
  final String time;
  final String amount;
  final List<Map<String, dynamic>> items;
  final double? total;

  const EditReceiptPage({
    Key? key,
    required this.receiptId,
    required this.merchantName,
    required this.date,
    required this.time,
    required this.amount,
    required this.items,
    this.total,
  }) : super(key: key);

  @override
  _EditReceiptPageState createState() => _EditReceiptPageState();
}

class _EditReceiptPageState extends State<EditReceiptPage> {
  late TextEditingController _merchantNameController;
  late TextEditingController _amountController;
  late List<Map<String, dynamic>> _items;
  late double _total;
  late String _finalCategory;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _merchantNameController = TextEditingController(text: widget.merchantName);
    _items = List<Map<String, dynamic>>.from(widget.items);

    // Calculate the total from the items
    _total = _items.fold<double>(
      0.0,
          (sum, item) => sum + (item['price'] ?? 0.0),
    );

    // Initialize the amount controller with total if available, otherwise use widget.amount
    _amountController = TextEditingController(
      text: widget.total != null && widget.total != 0.0
          ? widget.total!.toStringAsFixed(2)  // Display the total if available
          : widget.amount,
    );

    // Set initial values for date, time, and final category
    _selectedDate = DateTime.tryParse(widget.date) ?? DateTime.now();
    _selectedTime = _parseTime(widget.time) ?? TimeOfDay.now();
    _finalCategory = 'None';
    _updateFinalCategory();
  }



  TimeOfDay? _parseTime(String time) {
    try {
      final parts = time.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _merchantNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _saveReceipt() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        print('User not logged in');
        return;
      }

      final updatedData = {
        'merchant_name': _merchantNameController.text,
        'date': _selectedDate
            ?.toIso8601String()
            .split('T')
            .first ?? '',
        'time': '${_selectedTime?.hour}:${_selectedTime?.minute}',
        'amount': _amountController.text,
        'items': _items,
        'total': _total,
        'final_category': _finalCategory,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('receipts')
          .doc(widget.receiptId)
          .update(updatedData);

      print('Receipt updated successfully!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Receipt updated successfully!')),
      );

      Navigator.pop(context, true); // Notify parent page about the update.
    } catch (e) {
      print('Error updating receipt: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update receipt: $e')),
      );
    }
  }

  void _updateFinalCategory() {
    final categoryCounts = <String, int>{};

    for (var item in _items) {
      final category = item['category'] ?? 'None';
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    _finalCategory = categoryCounts.entries.reduce((a, b) {
      return a.value > b.value ? a : b;
    }).key;

    setState(() {});
  }

  void _updateTotal() {
    setState(() {
      // Recalculate the total based on the updated item prices
      _total = _items.fold<double>(
        0.0,
            (sum, item) => sum + (item['price'] ?? 0.0),
      );

      // Update the amount field to reflect the new total
      _amountController.text = _total.toStringAsFixed(2);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Receipt Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveReceipt,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Merchant Name
            TextField(
              controller: _merchantNameController,
              decoration: InputDecoration(labelText: 'Merchant Name'),
            ),
            SizedBox(height: 10),

            // Date Picker
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Date: ${_selectedDate
                        ?.toIso8601String()
                        .split('T')
                        .first ?? 'Select Date'}',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: _pickDate,
                ),
              ],
            ),
            SizedBox(height: 10),

            // Time Picker
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Time: ${_selectedTime?.format(context) ?? 'Select Time'}',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.access_time),
                  onPressed: _pickTime,
                ),
              ],
            ),
            SizedBox(height: 10),

            // Amount
            TextField(
              controller: _amountController,
              decoration: InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  // Update total based on the amount entered
                  _total = double.tryParse(value) ?? 0.0;
                });
              },
            ),

            SizedBox(height: 10),

            // Items List
            Text(
              'Items:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(labelText: 'Item Name'),
                            onChanged: (value) {
                              setState(() {
                                _items[index]['name'] = value;
                              });
                            },
                            controller: TextEditingController(
                              text: item['name'],
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(labelText: 'Price'),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _items[index]['price'] =
                                    double.tryParse(value) ?? 0.0;
                                _updateTotal(); // Update total after changing price
                              });
                            },
                            controller: TextEditingController(
                              text: item['price']?.toStringAsFixed(2) ?? '0.00',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _items.removeAt(index);
                              _updateTotal(); // Update total after removing item
                            });
                          },
                        ),
                      ],
                    ),
                    DropdownButton<String>(
                      value: item['category'] ?? 'None',
                      items: [
                        'Healthcare',
                        'Electronics',
                        'Groceries',
                        'Restaurant',
                        'Clothing',
                        'Others',
                        'None',
                      ].map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _items[index]['category'] = value;
                          _updateFinalCategory();
                        });
                      },
                      hint: Text('Select Category'),
                    ),
                    Divider(),
                  ],
                );
              },
            ),
            SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _items.add({'name': '', 'price': 0.0, 'category': 'None'});
                });
              },
              child: Text('Add Item'),
            ),
            Divider(),

            // Total Amount
            Text(
              'Total: \$${_total.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // Final Category
            Text(
              'Final Category: $_finalCategory',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
