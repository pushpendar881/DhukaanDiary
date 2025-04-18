import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:dukaan_diary/components/my_app_bar.dart';

class TransactionDetailPage extends StatefulWidget {
  final String transactionId;
  
  const TransactionDetailPage({
    super.key,
    required this.transactionId,
  });

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  bool isLoading = true;
  Map<String, dynamic> transactionData = {};
  List<Map<String, dynamic>> productItems = [];
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchTransactionDetails();
  }

  // Helper function to get value from any of multiple possible field names
  dynamic _getFieldValue(Map<String, dynamic> data, List<String> possibleFieldNames, [dynamic defaultValue]) {
    for (var fieldName in possibleFieldNames) {
      if (data[fieldName] != null) {
        return data[fieldName];
      }
    }
    return defaultValue;
  }

  // Extract timestamp from any of the supported field names
  DateTime? _extractTimestamp(Map<String, dynamic> data) {
    for (var fieldName in ['dateTime', 'datetime', 'date', 'Date', 'timestamp', 'createdAt', 'updatedAt']) {
      if (data[fieldName] != null && data[fieldName] is Timestamp) {
        return (data[fieldName] as Timestamp).toDate();
      }
    }
    return null;
  }

  Future<void> _fetchTransactionDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Fetch the main transaction document
      final DocumentSnapshot transactionDoc = await FirebaseFirestore.instance
          .collection('transactions')
          .doc(widget.transactionId)
          .get();

      if (!transactionDoc.exists) {
        setState(() {
          isLoading = false;
          errorMessage = 'Transaction not found';
        });
        return;
      }

      final data = transactionDoc.data() as Map<String, dynamic>;
      
      // Process the transaction data using helper methods
      final DateTime? transactionDate = _extractTimestamp(data);

      final Map<String, dynamic> processedData = {
        'id': transactionDoc.id,
        'userId': _getFieldValue(data, ['userId', 'customerId'], 'Unknown'),
        'customerName': _getFieldValue(data, ['customerName', 'Customername', 'customer'], 'Unknown Customer'),
        'totalAmount': _getFieldValue(data, ['totalAmount', 'Amount', 'amount', 'total'], 0),
        'date': transactionDate,
        'transactionNumber': _getFieldValue(data, ['transactionNumber', 'txnNumber', 'invoiceNumber'], ''),
        'notes': _getFieldValue(data, ['notes', 'note', 'description'], ''),
      };
      
      // Handle items based on the new database structure
      List<Map<String, dynamic>> items = [];
      
      if (data['items'] != null && data['items'] is List) {
        // Items are in an 'items' array as per the database structure
        final itemsList = List.from(data['items']);
        for (var item in itemsList) {
          if (item is Map<String, dynamic>) {
            items.add({
              'productName': item['productName'] ?? 'Unknown Product',
              'productNumber': item['productNumber'] ?? 'N/A',
              'productId': item['productId'] ?? '',
              'quantity': item['quantity'] ?? 0,
              'unitPrice': item['pricePerUnit'] ?? 0,
              'subtotal': item['totalPrice'] ?? 0,
            });
          }
        }
      } else {
        // Fallback for other structures
        try {
          // Try to fetch from subcollection
          final QuerySnapshot itemsSnapshot = await FirebaseFirestore.instance
              .collection('transactions')
              .doc(widget.transactionId)
              .collection('items')
              .get();
          
          if (itemsSnapshot.docs.isNotEmpty) {
            for (var doc in itemsSnapshot.docs) {
              final itemData = doc.data() as Map<String, dynamic>;
              items.add({
                'productName': _getFieldValue(itemData, ['productName', 'name'], 'Unknown Product'),
                'productNumber': _getFieldValue(itemData, ['productNumber', 'number'], 'N/A'),
                'productId': _getFieldValue(itemData, ['productId', 'id'], ''),
                'quantity': _getFieldValue(itemData, ['quantity'], 0),
                'unitPrice': _getFieldValue(itemData, ['pricePerUnit', 'unitPrice', 'price'], 0),
                'subtotal': _getFieldValue(itemData, ['totalPrice', 'subtotal'], 0),
              });
            }
          }
        } catch (e) {
          print('Error fetching items subcollection: $e');
        }
      }

      setState(() {
        transactionData = processedData;
        productItems = items;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load transaction details. Please try again.';
      });
      print('Error in _fetchTransactionDetails: $e');
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '₹0.00';
    
    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
      locale: 'en_IN',
    );
    
    if (amount is int) {
      return formatter.format(amount.toDouble());
    } else if (amount is double) {
      return formatter.format(amount);
    }
    
    return '₹$amount';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: MyAppBar(pageinfo: 'Transaction Details'),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading transaction details...'),
          ],
        ),
      );
    }
    
    if (errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchTransactionDetails,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Invoice-like header
          _buildInvoiceHeader(),
          
          const SizedBox(height: 24),
          
          // Items section
          _buildItemsSection(),
          
          const SizedBox(height: 20),
          
          // Total section
          _buildTotalSection(),
          
          const SizedBox(height: 30),
          
          // Action button (only Back now)
          _buildActionButton(),
        ],
      ),
    );
  }
  
  Widget _buildInvoiceHeader() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invoice-like header with titled section
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SALE RECEIPT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    transactionData['transactionNumber'] != null && 
                    transactionData['transactionNumber'].toString().isNotEmpty
                        ? transactionData['transactionNumber']
                        : '# ${transactionData['id'].toString().substring(0, min(8, transactionData['id'].toString().length))}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Customer info
            const Text(
              'Customer Information',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  transactionData['customerName'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            // Date and payment info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Date',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transactionData['date'] != null
                            ? DateFormat('yyyy-MM-dd').format(transactionData['date'])
                            : 'Not specified',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Time',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transactionData['date'] != null
                            ? DateFormat('hh:mm a').format(transactionData['date'])
                            : 'Not specified',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Notes section, if available
            if (transactionData['notes'] != null && transactionData['notes'].toString().isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Notes',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transactionData['notes'].toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildItemsSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Items',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Header row
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Product',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Qty',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Price',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Total',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(),
            
            // Item rows
            if (productItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    'No items found',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              ...productItems.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['productName'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (item['productNumber'] != null && item['productNumber'] != 'N/A')
                                Text(
                                  '#${item['productNumber']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${item['quantity']}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _formatCurrency(item['unitPrice']),
                            textAlign: TextAlign.end,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _formatCurrency(item['subtotal']),
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                  ],
                ),
              )).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTotalSection() {
    // Calculate the total from items
    double calculatedTotal = 0;
    for (var item in productItems) {
      calculatedTotal += (item['subtotal'] ?? 0);
    }
    
    // Use the calculated total or the one from transaction data, whichever is more reliable
    final displayedTotal = transactionData['totalAmount'] ?? calculatedTotal;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text(_formatCurrency(calculatedTotal)),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _formatCurrency(displayedTotal),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton() {
    return Center(
      child: SizedBox(
        width: 200, // Set a fixed width for the button
        child: OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blue,
            side: const BorderSide(color: Colors.blue),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}

// Helper function for min() that was used in the code but not defined
int min(int a, int b) {
  return a < b ? a : b;
}