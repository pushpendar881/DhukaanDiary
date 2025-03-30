import 'package:dukaan_diary/components/my_app_bar.dart';
import 'package:flutter/material.dart';

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

  List<Map<String, dynamic>> transactions = List.generate(15, (index) {
    DateTime now = DateTime.now();
    DateTime randomDate = now.subtract(Duration(days: (index % 12) * 30));
    return {
      "product": "Product ${(index % 5) + 1}",
      "productNumber": "P00${index + 1}",
      "quantity": (index + 1) * 2,
      "amount": (index + 1) * 1000,
      "customer": index % 3 == 0 ? "Customer ${index + 1}" : "Customer",
      "date": randomDate,
    };
  });

  List<Map<String, dynamic>> getFilteredTransactions() {
    DateTime now = DateTime.now();
    int months = int.parse(selectedFilter.split(" ")[0]);
    DateTime cutoffDate = now.subtract(Duration(days: months * 30));
    return transactions.where((tx) => tx["date"].isAfter(cutoffDate)).toList();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredTransactions = getFilteredTransactions();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar( pageinfo: 'Sales History'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: DropdownButton<String>(
              value: selectedFilter,
              onChanged: (String? newValue) {
                setState(() {
                  selectedFilter = newValue!;
                });
              },
              items:
                  filters.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) {
                var tx = filteredTransactions[index];
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
                          "Date: ${tx['date'].toLocal().toString().split(' ')[0]}",
                        ),
                      ],
                    ),
                    leading: const Icon(
                      Icons.shopping_cart,
                      color: Colors.blue,
                      size: 30,
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
