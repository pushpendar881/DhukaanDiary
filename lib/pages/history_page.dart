import 'package:dukaan_diary/components/my_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:dukaan_diary/pages/transactiondetailpage.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String selectedFilter = "6 Months";
  final List<String> filters = ["2 Months", "4 Months", "6 Months", "12 Months"];
  
  bool isLoading = true;
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];
  String errorMessage = '';
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchController = TextEditingController();
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchTransactions(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredTransactions = List.from(transactions);
        isSearching = false;
      } else {
        isSearching = true;
        filteredTransactions = transactions.where((tx) {
          // Search by ID or product number or name (case insensitive)
          final id = tx['id'].toString().toLowerCase();
          final productNumber = tx['productNumber']?.toString().toLowerCase() ?? '';
          final productName = tx['product']?.toString().toLowerCase() ?? '';
          final customerName = tx['customer']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          
          return id.contains(searchLower) || 
                 productNumber.contains(searchLower) ||
                 productName.contains(searchLower) ||
                 customerName.contains(searchLower);
        }).toList();
      }
    });
  }

  // Extracts timestamp from any supported field name format
  DateTime? _extractTimestamp(Map<String, dynamic> data) {
    // Check for various datetime field names in order of preference
    for (var fieldName in ['Datetime', 'datetime', 'date', 'Date', 'timestamp']) {
      if (data[fieldName] != null && data[fieldName] is Timestamp) {
        return (data[fieldName] as Timestamp).toDate();
      }
    }
    return null;
  }

  // Gets a value from a map checking multiple possible field names
  dynamic _getFieldValue(Map<String, dynamic> data, List<String> possibleFieldNames, [dynamic defaultValue]) {
    for (var fieldName in possibleFieldNames) {
      if (data[fieldName] != null) {
        return data[fieldName];
      }
    }
    return defaultValue;
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
        
        // Extract date using the more robust helper function
        DateTime? transactionDate = _extractTimestamp(data);
        
        // Skip if transaction is older than the cutoff or has no date
        if (transactionDate == null || transactionDate.isBefore(cutoffDate)) {
          continue;
        }

        // Handle multiple products scenario
        if (data['products'] != null && data['products'] is List) {
          // Multiple products in one transaction
          final productsList = data['products'] as List;
          
          for (var product in productsList) {
            if (product is Map<String, dynamic>) {
              loadedTransactions.add({
                'id': doc.id,
                'product': product['name'] ?? 'Unknown Product',
                'productNumber': product['number'] ?? 'N/A',
                'quantity': product['quantity'] ?? 0,
                'amount': product['price'] != null && product['quantity'] != null 
                    ? (product['price'] * product['quantity']).toDouble() 
                    : 0,
                'customer': _getFieldValue(data, ['customerName', 'Customername', 'customer'], 'Customer'),
                'date': transactionDate,
                'fullData': data, // Store full data for detail view
              });
            }
          }
        } else {
          // Single product transaction - use helper function for field names
          loadedTransactions.add({
            'id': doc.id,
            'product': _getFieldValue(data, ['productname', 'productName', 'product'], 'Unknown Product'),
            'productNumber': _getFieldValue(data, ['productnumber', 'productNumber'], 'N/A'),
            'quantity': _getFieldValue(data, ['productQuantity', 'quantity'], 0),
            'amount': _getFieldValue(data, ['Amount', 'amount', 'total'], 0),
            'customer': _getFieldValue(data, ['customerName', 'Customername', 'customer'], 'Customer'),
            'date': transactionDate,
            'fullData': data, // Store full data for detail view
          });
        }
      }

      // Sort transactions by date (newest first)
      loadedTransactions.sort((a, b) => b['date'].compareTo(a['date']));

      setState(() {
        transactions = loadedTransactions;
        filteredTransactions = loadedTransactions;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching transactions: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load transactions. Please check your connection and try again.';
      });
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '₹0';
    if (amount is int) return '₹$amount';
    if (amount is double) return '₹${amount.toStringAsFixed(2)}';
    return '₹$amount';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar(pageinfo: 'Sales History'),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by ID, Product or Customer',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchTransactions('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: _searchTransactions,
            ),
          ),

          // Time Filter (only visible when not searching)
          if (!isSearching)
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
          
          // Content section
          _buildContentSection(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add transaction page
          // Uncomment when AddTransactionPage is available
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Sale',
      ),
    );
  }
  
  Widget _buildContentSection() {
    if (isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (errorMessage.isNotEmpty) {
      return Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchTransactions,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    if (filteredTransactions.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSearching ? Icons.search_off : Icons.inventory,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                isSearching
                    ? 'No transactions found matching your search'
                    : 'No sales transactions found for this period',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              if (isSearching) 
                const SizedBox(height: 8),
              if (isSearching)
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    _searchTransactions('');
                  },
                  child: const Text('Clear Search'),
                ),
            ],
          ),
        ),
      );
    }
    
    return Expanded(
      child: RefreshIndicator(
        onRefresh: _fetchTransactions,
        child: ListView.builder(
          itemCount: filteredTransactions.length,
          itemBuilder: (context, index) {
            return _buildTransactionCard(filteredTransactions[index]);
          },
        ),
      ),
    );
  }
  
  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 8,
      ),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to transaction details page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionDetailPage(
                transactionId: tx['id'],
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon column
              const Padding(
                padding: EdgeInsets.only(top: 8.0, right: 12.0),
                child: Icon(
                  Icons.shopping_cart,
                  color: Colors.blue,
                  size: 30,
                ),
              ),
              
              // Main content column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Product name
                        Expanded(
                          child: Text(
                            tx['product'] ?? 'Unknown Product',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Amount
                        Text(
                          _formatAmount(tx['amount']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // ID and Product Number
                    Row(
                      children: [
                        Text(
                          "ID: ${tx['id'].toString().substring(0, min(tx['id'].toString().length, 8))}${tx['id'].toString().length > 8 ? '...' : ''}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Prod#: ${tx['productNumber'] ?? 'N/A'}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Quantity and Customer in same row
                    Row(
                      children: [
                        const Icon(Icons.format_list_numbered, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "${tx['quantity'] ?? 0}",
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.person_outline, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            tx['customer'] ?? 'Customer',
                            style: TextStyle(color: Colors.grey[700]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Date with icon
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('yyyy-MM-dd').format(tx['date']),
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('HH:mm').format(tx['date']),
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    // View details indicator
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "View Details",
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.blue[700],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper function to get min value between two integers
int min(int a, int b) {
  return a < b ? a : b;
}