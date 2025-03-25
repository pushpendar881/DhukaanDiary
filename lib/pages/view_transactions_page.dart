import 'package:dukaan_diary/components/my_app_bar.dart';
import 'package:flutter/material.dart';

class ViewTransactionsPage extends StatelessWidget {
  final String phoneNumber;
  const ViewTransactionsPage({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    // Dummy transactions data
    List<Map<String, dynamic>> transactions = [
      {"date": "2024-03-01", "amount": 5000, "type": "Paid"},
      {"date": "2024-03-05", "amount": 2000, "type": "Received"},
      {"date": "2024-03-10", "amount": 1500, "type": "Paid"},
    ];

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: MyAppBar(shopname: 'Shop Name', pageinfo: 'Transactions'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Transactions with: $phoneNumber",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Icon(Icons.history, color: Colors.white),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                var tx = transactions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: Icon(
                      tx['type'] == 'Paid' ? Icons.arrow_upward : Icons.arrow_downward,
                      color: tx['type'] == 'Paid' ? Colors.red : Colors.green,
                    ),
                    title: Text("Amount: ₹${tx['amount']}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: Text("Date: ${tx['date']}"),
                    trailing: Text(
                      tx['type'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: tx['type'] == 'Paid' ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}