import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class ReportsPage extends StatefulWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategory;
  double _minAmount = 0;
  double _maxAmount = 1000;

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Monthly Reports'),
      ),
      body: SingleChildScrollView(  // Wrap the entire body in SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter by Date Range',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _selectStartDate,
                    child: Text(_startDate == null
                        ? 'Select Start Date'
                        : 'Start: ${_startDate!.toLocal()}'.split(' ')[0]),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _selectEndDate,
                    child: Text(_endDate == null
                        ? 'Select End Date'
                        : 'End: ${_endDate!.toLocal()}'.split(' ')[0]),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'Filter by Category',
                style: TextStyle(fontSize: 18),
              ),
              DropdownButton<String>(
                value: _selectedCategory,
                hint: Text("Select Category"),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                items: ['All', 'Restaurant', 'Electronics', 'Clothing', 'Groceries', 'Healthcare']
                    .map<DropdownMenuItem<String>>((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              Text(
                'Filter by Amount Range (\$$_minAmount - \$$_maxAmount)',
                style: TextStyle(fontSize: 18),
              ),
              RangeSlider(
                min: 0,
                max: 1000,
                divisions: 100,
                values: RangeValues(_minAmount, _maxAmount),
                onChanged: (RangeValues values) {
                  setState(() {
                    _minAmount = values.start;
                    _maxAmount = values.end;
                  });
                },
              ),
              SizedBox(height: 20),
              // Make sure that the list view is scrollable if needed
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .collection('receipts')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading data"));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No data available"));
                  }

                  // Process data to calculate total amounts per category
                  final categoryTotals = <String, double>{};

                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final dateString = data['date'] ?? '';
                    final finalCategory = data['final_category'] ?? '';
                    final amount = double.tryParse(data['amount']?.toString() ?? '0') ?? 0;

                    if (dateString.isNotEmpty) {
                      final receiptDate = DateTime.parse(dateString);

                      // Apply all selected filters
                      bool dateFilter = (_startDate == null || receiptDate.isAfter(_startDate!)) &&
                          (_endDate == null || receiptDate.isBefore(_endDate!.add(Duration(days: 1))));
                      bool categoryFilter = _selectedCategory == null || _selectedCategory == 'All' || finalCategory == _selectedCategory;
                      bool amountFilter = amount >= _minAmount && amount <= _maxAmount;

                      if (dateFilter && categoryFilter && amountFilter) {
                        categoryTotals[finalCategory] = (categoryTotals[finalCategory] ?? 0) + amount;
                      }
                    }
                  }

                  // Prepare data for Pie chart
                  List<MapEntry<String, double>> sortedCategoryTotals = categoryTotals.entries.toList();
                  sortedCategoryTotals.sort((a, b) => b.value.compareTo(a.value)); // Sort categories by total amount

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filtered Category Distribution',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                      CustomPaint(
                        size: Size(300, 300),
                        painter: PieChartPainter(categoryTotals: sortedCategoryTotals),
                      ),
                      SizedBox(height: 20),
                      PieChartLegend(categoryTotals: sortedCategoryTotals),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to select start date
  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  // Function to select end date
  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }
}

class PieChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> categoryTotals;

  PieChartPainter({required this.categoryTotals});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..style = PaintingStyle.fill;

    // Background color
    paint.color = Colors.grey[200]!;
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, size.height), paint);

    // Define the center and radius of the pie chart
    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = min(size.width / 2, size.height / 2);

    // Total value to calculate the proportions
    double totalAmount = categoryTotals.fold(0, (sum, entry) => sum + entry.value);

    // Calculate the starting angle for each slice
    double startAngle = -pi / 2; // Start at the top (12 o'clock position)

    for (int i = 0; i < categoryTotals.length; i++) {
      paint.color = _getColorForCategory(i);
      double sweepAngle = (categoryTotals[i].value / totalAmount) * 2 * pi; // Proportionate angle for each category
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      startAngle += sweepAngle; // Update start angle for next slice
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }

  Color _getColorForCategory(int index) {
    // You can customize the colors here based on the category index
    List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.yellow,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }
}

class PieChartLegend extends StatelessWidget {
  final List<MapEntry<String, double>> categoryTotals;

  PieChartLegend({required this.categoryTotals});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(categoryTotals.length, (i) {
        return Row(
          children: [
            Container(
              width: 20,
              height: 20,
              color: _getColorForCategory(i),
            ),
            SizedBox(width: 10),
            Text('${categoryTotals[i].key}: \$${categoryTotals[i].value.toStringAsFixed(2)}'),
          ],
        );
      }),
    );
  }

  Color _getColorForCategory(int index) {
    // You can customize the colors here based on the category index
    List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.yellow,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }
}
