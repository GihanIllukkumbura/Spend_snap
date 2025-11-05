import 'package:firebasefluttter/screens/receipt_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'EditProfilePage.dart';
import 'OCRService.dart';
import 'receipts_page.dart';
import 'reports_page.dart';
import 'settings_page.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final User? user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _recentReceipts = [];
  int _selectedIndex = 0;
  bool isOptionsVisible = false;
  final ImagePicker _picker = ImagePicker();
  double spentThisMonth = 0.0;
  double spentLastMonth = 0.0;


  @override
  void initState() {
    super.initState();
    _fetchMonthlySpent();
  }
  void _fetchMonthlySpent() async {
    if (user == null) return;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
    final endOfLastMonth = startOfMonth.subtract(const Duration(days: 1));

    setState(() {
      spentThisMonth = 0.0;
      spentLastMonth = 0.0;
    });

    FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('receipts')
        .snapshots()
        .listen((snapshot) {
      double currentMonthTotal = 0.0;
      double lastMonthTotal = 0.0;

      for (var doc in snapshot.docs) {
        String dateString = doc['date'] ?? '';  // Assuming the date is stored as a string in 'YYYY-MM-DD' format.
        DateTime receiptDate = DateTime.parse(dateString);  // Convert string to DateTime.

        if (receiptDate.isAfter(startOfMonth)) {
          // Current month
          currentMonthTotal += double.tryParse(doc['amount'] ?? '0') ?? 0;
        } else if (receiptDate.isAfter(startOfLastMonth) && receiptDate.isBefore(startOfMonth)) {
          // Last month
          lastMonthTotal += double.tryParse(doc['amount'] ?? '0') ?? 0;
        }
      }

      setState(() {
        spentThisMonth = currentMonthTotal;
        spentLastMonth = lastMonthTotal;
      });
    });
  }




  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good morning!";
    } else if (hour < 17) {
      return "Good afternoon!";
    } else {
      return "Good evening!";
    }
  }

  final List<Widget> _pages = [
    const HomeContent(),  // Home page where MonthlySpentSection is visible
    const ReceiptsPage(),
    const ReportsPage(),
    const SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleOptions() {
    setState(() {
      isOptionsVisible = !isOptionsVisible;
    });
  }

  Future<void> _openGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      await _processReceiptImage(imageFile);
    }
  }

  Future<void> _openCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      await _processReceiptImage(imageFile);
    }
  }

  Future<void> _processReceiptImage(File imageFile) async {
    setState(() {
      _recentReceipts.insert(0, {
        "image": imageFile,
        "merchant_name": "Processing...",
      });
      if (_recentReceipts.length > 5) _recentReceipts.removeLast();
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid.isEmpty) {
        throw Exception("User is not logged in or UID is empty.");
      }

      print("User UID: ${user.uid}");

      String filePath = 'receipts/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageReference = FirebaseStorage.instance.ref().child(filePath);

      UploadTask uploadTask = storageReference.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();
      print("Download URL: $downloadUrl");

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('receipts')
          .add({
        "imageUrl": downloadUrl,
        "merchant_name": "Unknown Merchant",
        "amount": "N/A",
        "timestamp": FieldValue.serverTimestamp(),
      }).then((value) {
        print("Receipt successfully saved in Firestore");
      }).catchError((error) {
        print("Error saving receipt to Firestore: $error");
      });

      setState(() {
        _recentReceipts[0] = {
          "image": downloadUrl,
          "merchant_name": "Unknown Merchant",
          "amount": "N/A",
        };
      });
      print("Receipt saved successfully.");
    } catch (e) {
      print("Error during image processing: $e");
      setState(() {
        _recentReceipts[0] = {
          "image": imageFile,
          "merchant_name": "Error",
          "amount": "Error",
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: const Color.fromRGBO(183, 28, 28, 1),
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getGreeting(),
                  style: const TextStyle(fontSize: 24, color: Colors.white),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 25,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Icon(
                                Icons.person,
                                color: Color.fromRGBO(183, 28, 28, 1),
                                size: 30,
                              );
                            }

                            var userData = snapshot.data!.data() as Map<String, dynamic>;
                            String? imageUrl = userData['image_url'];

                            // If the image URL exists, display the image, otherwise, show the default icon
                            return imageUrl != null && imageUrl.isNotEmpty
                                ? CircleAvatar(
                              backgroundImage: NetworkImage(imageUrl),
                              radius: 25,
                            )
                                : const Icon(
                              Icons.person,
                              color: Color.fromRGBO(183, 28, 28, 1),
                              size: 25,
                            );
                          },
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Color.fromRGBO(183, 28, 28, 1),
                              size: 0,
                            ),
                            onPressed: () {
                              // Navigate to the EditProfilePage when the icon is pressed
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ProfileEditPage()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),


              ],
            ),
          ),
          elevation: 0,
        ),
      ),
      body: Container(
        color: const Color.fromRGBO(66, 66, 66, 0.576),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            if (_selectedIndex == 0) MonthlySpentSection(
              spentThisMonth: spentThisMonth,
              spentLastMonth: spentLastMonth,
            ),  // Show only on Home page
            const SizedBox(height: 20),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: _pages,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Stack(
        children: [
          if (isOptionsVisible) ...[
            Positioned(
              right: 20,
              bottom: 100,
              child: AnimatedOpacity(
                opacity: isOptionsVisible ? 1 : 0,
                duration: Duration(milliseconds: 300),
                child: FloatingActionButton(
                  heroTag: "gallery",
                  onPressed: _openGallery,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.photo, color: Color.fromRGBO(183, 28, 28, 1)),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 160,
              child: AnimatedOpacity(
                opacity: isOptionsVisible ? 1 : 0,
                duration: Duration(milliseconds: 300),
                child: FloatingActionButton(
                  heroTag: "camera",
                  onPressed: _openCamera,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.camera, color: Color.fromRGBO(183, 28, 28, 1)),
                ),
              ),
            ),
          ],
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              onPressed: _toggleOptions,
              backgroundColor: Color.fromRGBO(183, 28, 28, 1),
              child: Icon(
                isOptionsVisible ? Icons.close : Icons.add,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      backgroundColor: const Color.fromRGBO(66, 66, 66, 0.576),  // Optional background color
      elevation: 0,
      selectedItemColor: const Color.fromRGBO(183, 28, 28, 1), // Red color for selected item
      unselectedItemColor: const Color.fromRGBO(0, 0, 0, 1),   // Black color for unselected items
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "Receipts"),
        BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: "Reports"),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
      ],
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
    );
  }


}

class MonthlySpentSection extends StatelessWidget {
  final double spentThisMonth;
  final double spentLastMonth;

  const MonthlySpentSection({
    Key? key,
    required this.spentThisMonth,
    required this.spentLastMonth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildMonthlySpentDetail("Spent this month", "Rs ${spentThisMonth.toStringAsFixed(2)}"),
          _buildMonthlySpentDetail("Last month", "Rs ${spentLastMonth.toStringAsFixed(2)}", isLastMonth: true),
        ],
      ),
    );
  }

  Widget _buildMonthlySpentDetail(String title, String amount, {bool isLastMonth = false}) {
    return Column(
      crossAxisAlignment: isLastMonth ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Color.fromRGBO(255, 255, 255, 0.6)),
        ),
        Text(
          amount,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }
}



class HomeContent extends StatelessWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromRGBO(66, 66, 66, 0.576),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Top 3 categories this month", style: TextStyle(fontSize: 16, color: Colors.white)),
          const SizedBox(height: 10),
          _buildTopCategories(),
          const SizedBox(height: 20),
          const Text("Recent receipts", style: TextStyle(fontSize: 16, color: Colors.white)),
          const SizedBox(height: 10),
          Expanded(child: _buildRecentReceipts()),
        ],
      ),
    );
  }

  Widget _buildTopCategories() {
    final User? user = FirebaseAuth.instance.currentUser;

    return StreamBuilder(

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
          return const Center(child: Text("Error loading categories"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No data available"));
        }

        // Process data
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final categoryTotals = <String, double>{};

        for (var doc in snapshot.data!.docs) {
          final data = doc.data();
          final dateString = data['date'] ?? ''; // Assuming date is stored as a string in 'YYYY-MM-DD' format.
          final finalCategory = data['final_category'] ?? '';
          final amount = double.tryParse(data['amount']?.toString() ?? '0') ?? 0;

          if (dateString.isNotEmpty) {
            final receiptDate = DateTime.parse(dateString);
            if (receiptDate.isAfter(startOfMonth)) {
              // Current month: aggregate totals by category
              categoryTotals[finalCategory] = (categoryTotals[finalCategory] ?? 0) + amount;
            }
          }
        }

        // Sort categories by totals in descending order and take the top 3
        final topCategories = categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topThree = topCategories.take(3).toList();

        // Build UI
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: topThree.map((entry) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(66, 66, 66, 0.576),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.category, color: Color.fromRGBO(183, 28, 28, 1)),
                    const SizedBox(height: 10),
                    Text(
                      entry.key,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    Text(
                      "Rs${entry.value.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }


  Widget _buildRecentReceipts() {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Center(child: Text('You need to log in to see your receipts.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('receipts')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No receipts found.'));
        }

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var receiptData = snapshot.data!.docs[index];
            DateTime timestamp = (receiptData['timestamp'] as Timestamp).toDate();
            String date = "${timestamp.day}/${timestamp.month}/${timestamp.year}";
            String time = "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}";

            return _buildReceiptCard(
              context, // Pass the context here
              date,
              time,
              receiptData['amount'],
              receiptData['imageUrl'],
            );
          },
        );
      },
    );
  }

  Widget _buildReceiptCard(BuildContext context, String date, String time, String amount, String imagePath) {
    return GestureDetector(
      onTap: () {
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => ReceiptDetailPage(
        //       imageUrl: imagePath,
        //       date: date,
        //       time: time,
        //       amount: amount,
        //     ),
        //   ),
        // );
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          children: [
            Expanded(
              child: imagePath.startsWith('http')
                  ? Image.network(imagePath, fit: BoxFit.cover)
                  : Image.asset(imagePath, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            Text(date, style: const TextStyle(fontSize: 14, color: Color.fromRGBO(255, 255, 255, 1))), // white color in RGB
            Text(time, style: const TextStyle(fontSize: 12, color: Color.fromRGBO(255, 255, 255, 1))), // white color in RGB
            Text(amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color.fromRGBO(255, 255, 255, 1))), // white color in RGB
          ],
        ),
      ),
    );
  }
}
