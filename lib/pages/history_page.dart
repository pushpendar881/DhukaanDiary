import 'package:dukaan_diary/components/my_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String selectedFilter = "6 Months";
  final List<String> filters = [
    "2 Months",
    "4 Months",
    "6 Months",
    "12 Months",
  ];
  
  bool isLoading = true;
  List<Map<String, dynamic>> transactions = [];
  String errorMessage = '';
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    if (user == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'You must be logged in to view sales history';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Simple query with no ordering to avoid index requirements
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: user!.uid)
          .get();

      // Calculate cutoff date based on filter
      DateTime now = DateTime.now();
      int months = int.parse(selectedFilter.split(" ")[0]);
      DateTime cutoffDate = now.subtract(Duration(days: months * 30));
      
      final List<Map<String, dynamic>> loadedTransactions = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Extract date
        DateTime? transactionDate;
        if (data['Datetime'] != null && data['Datetime'] is Timestamp) {
          transactionDate = (data['Datetime'] as Timestamp).toDate();
          
          // Filter by date in-memory
          if (transactionDate.isBefore(cutoffDate)) {
            continue; // Skip this transaction as it's older than the cutoff
          }
        }

        loadedTransactions.add({
          'id': doc.id,
          'product': data['productname'] ?? 'Unknown Product',
          'productNumber': data['productnumber'] ?? 'N/A',
          'quantity': data['productQuantity'] ?? 0,
          'amount': data['Amount'] ?? 0,
          'customer': data['Customername'] ?? 'Customer',
          'date': transactionDate ?? DateTime.now(),
        });
      }

      // Sort transactions by date (newest first) in memory
      loadedTransactions.sort((a, b) => b['date'].compareTo(a['date']));

      setState(() {
        transactions = loadedTransactions;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading transactions: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar(pageinfo: 'Sales History'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Time Period:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButton<String>(
                  value: selectedFilter,
                  onChanged: (String? newValue) {
                    if (newValue != null && newValue != selectedFilter) {
                      setState(() {
                        selectedFilter = newValue;
                      });
                      _fetchTransactions();
                    }
                  },
                  items: filters.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          if (isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (errorMessage.isNotEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else if (transactions.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No sales transactions found for this period',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchTransactions,
                child: ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    var tx = transactions[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 8,
                      ),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: Text(
                          "Product: ${tx['product']} (${tx['productNumber']})",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Quantity Sold: ${tx['quantity']}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Total Amount: ₹${tx['amount']}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Customer: ${tx['customer']}",
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            Text(
                              "Date: ${DateFormat('yyyy-MM-dd').format(tx['date'])}",
                            ),
                          ],
                        ),
                        leading: const Icon(
                          Icons.shopping_cart,
                          color: Colors.blue,
                          size: 30,
                        ),
                        onTap: () {
                          // Optional: Navigate to transaction details
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => TransactionDetailPage(
                          //       transactionId: tx['id'],
                          //     ),
                          //   ),
                          // );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add transaction page
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => AddTransactionPage(),
          //   ),
          // ).then((_) => _fetchTransactions());
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Sale',
      ),
    );
  }
}