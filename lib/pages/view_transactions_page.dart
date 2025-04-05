import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dukaan_diary/pages/add_transaction_page_contact.dart';
import 'package:intl/intl.dart';

class ViewTransactionsPage extends StatelessWidget {
  final String contactId;
  final String contactName;
  final String phoneNumber;

  const ViewTransactionsPage({
    super.key,
    required this.contactId,
    required this.contactName,
    required this.phoneNumber,
  });

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: Colors.blue,
      ),
      body: user == null
          ? const Center(child: Text('Not authenticated'))
          : Column(
              children: [
                // Contact info header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.shade50,
                  child: Row(
                    children: [
                      const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contactName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(phoneNumber),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Balance summary
                FutureBuilder<Map<String, dynamic>>(
                  future: calculateBalance(user.uid, contactId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }
                    
                    final data = snapshot.data!;
                    final totalReceived = data['received'] as double;
                    final totalPaid = data['paid'] as double;
                    final balance = totalReceived - totalPaid;
                    
                    return Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey.shade100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('Received',
                                  style: TextStyle(color: Colors.green)),
                              Text('₹${totalReceived.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            children: [
                              const Text('Paid',
                                  style: TextStyle(color: Colors.red)),
                              Text('₹${totalPaid.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            children: [
                              const Text('Balance',
                                  style: TextStyle(color: Colors.blue)),
                              Text(
                                '₹${balance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: balance >= 0 ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                // Transactions list
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('transactions')
                        .where('contactId', isEqualTo: contactId)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      
                      if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('No transactions found for this contact'),
                        );
                      }
                      
                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          
                          final type = data['type'] as String;
                          final amount = data['amount'] as double;
                          final date = data['date'] as String;
                          final description = data['description'] as String? ?? '';
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: type == 'Received' 
                                    ? Colors.green.shade100 
                                    : Colors.red.shade100,
                                child: Icon(
                                  type == 'Received'
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: type == 'Received'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              title: Text(
                                '₹${amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: type == 'Received'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(date),
                                  if (description.isNotEmpty)
                                    Text(
                                      description,
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                onSelected: (value) async {
                                  if (value == 'delete') {
                                    // Delete the transaction
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Transaction'),
                                        content: const Text(
                                            'Are you sure you want to delete this transaction?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Delete',
                                                style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      try {
                                        await doc.reference.delete();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content: Text('Transaction deleted')),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                              content: Text('Error: ${e.toString()}')),
                                        );
                                      }
                                    }
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionPageContact(
                contactId: contactId,
                phoneNumber: phoneNumber,
              ),
            ),
          ).then((value) {
            // Refresh the page if a transaction was added
            if (value == true) {
              setState(() {});
            }
          });
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<Map<String, dynamic>> calculateBalance(String userId, String contactId) async {
    final transactions = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .where('contactId', isEqualTo: contactId)
        .get();
    
    double totalReceived = 0;
    double totalPaid = 0;
    
    for (final doc in transactions.docs) {
      final data = doc.data();
      final double amount = (data['amount'] as num).toDouble();
      final String type = data['type'] as String;
      
      if (type == 'Received') {
        totalReceived += amount;
      } else if (type == 'Paid') {
        totalPaid += amount;
      }
    }
    
    return {
      'received': totalReceived,
      'paid': totalPaid,
    };
  }

  // Helper method to trigger rebuild
  void setState(VoidCallback fn) {
    fn();
  }
}