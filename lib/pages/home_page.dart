import 'package:dukaan_diary/components/my_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:dukaan_diary/pages/trasaction_anaylsis.dart';
import 'package:dukaan_diary/pages/TransactionDetailPage.dart'; // Import for transaction details

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> recentTransactions = [];
  bool isLoading = true;
  String errorMessage = '';
  Map<String, dynamic> salesStats = {
    'todaySales': 0.0,
    'weekSales': 0.0,
    'monthSales': 0.0,
    'totalItems': 0,
  };
  
  @override
  void initState() {
    super.initState();
    _fetchRecentTransactions();
    _fetchSalesStats();
  }
  
  Future<void> _fetchRecentTransactions() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        setState(() {
          errorMessage = 'You must be logged in to view transactions';
          isLoading = false;
        });
        return;
      }
      
      // Query Firestore for the most recent 5 transactions from the current user
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      
      final List<Map<String, dynamic>> transactions = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Extract timestamp from any field that might contain it
        DateTime? transactionDate;
        for (var fieldName in ['dateTime', 'createdAt', 'Datetime', 'datetime', 'date', 'Date', 'timestamp']) {
          if (data[fieldName] != null) {
            if (data[fieldName] is Timestamp) {
              transactionDate = (data[fieldName] as Timestamp).toDate();
              break;
            } else if (data[fieldName] is String) {
              // Try to parse string dates if available
              try {
                transactionDate = DateTime.parse(data[fieldName]);
                break;
              } catch (_) {}
            }
          }
        }
        
        // Get customer name from any applicable field
        String customerName = 'Unknown Customer';
        for (var fieldName in ['customerName', 'Customername', 'customer', 'Customer']) {
          if (data[fieldName] != null && data[fieldName].toString().isNotEmpty) {
            customerName = data[fieldName].toString();
            break;
          }
        }
        
        // Use totalAmount field or fallback to any amount field
        num amount = 0;
        for (var fieldName in ['totalAmount', 'Amount', 'amount', 'total']) {
          if (data[fieldName] != null) {
            // Handle different numeric formats
            if (data[fieldName] is num) {
              amount = data[fieldName];
              break;
            } else if (data[fieldName] is String) {
              try {
                amount = num.parse(data[fieldName]);
                break;
              } catch (_) {}
            }
          }
        }
        
        // Extract product names from items array if it exists
        List<String> productNames = [];
        if (data['items'] != null && data['items'] is List) {
          for (var item in data['items']) {
            if (item is Map && item['productName'] != null) {
              productNames.add(item['productName'].toString());
            } else if (item is Map && item['name'] != null) {
              productNames.add(item['name'].toString());
            }
          }
        }
        
        // Create a descriptive product string
        String productText = productNames.isNotEmpty 
            ? productNames.length == 1 
                ? productNames[0]
                : '${productNames[0]} +${productNames.length - 1} more'
            : data['productName'] ?? data['productname'] ?? data['product'] ?? 'Multiple Items';
        
        transactions.add({
          'id': doc.id,
          'product': productText,
          'amount': amount,
          'customer': customerName,
          'date': transactionDate ?? DateTime.now(),
          'transactionNumber': data['transactionNumber'] ?? '',
          'rawData': data, // Store raw data for debugging if needed
        });
      }
      
      if (mounted) {
        setState(() {
          recentTransactions = transactions;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error fetching transactions: ${e.toString()}';
          isLoading = false;
        });
        print('Error in _fetchRecentTransactions: $e');
      }
    }
  }
  
  Future<void> _fetchSalesStats() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) return;
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);
      
      // Get all transactions for this month to process locally
      final transactionsSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: currentUser.uid)
          .get();
      
      double todaySales = 0.0;
      double weekSales = 0.0;
      double monthSales = 0.0;
      int totalItems = 0;
      
      // Process all transactions locally for more reliable date filtering
      for (var doc in transactionsSnapshot.docs) {
        final data = doc.data();
        DateTime? transactionDate;
        
        // Find date field in various formats
        for (var fieldName in ['dateTime', 'createdAt', 'Datetime', 'datetime', 'date', 'Date', 'timestamp']) {
          if (data[fieldName] != null) {
            if (data[fieldName] is Timestamp) {
              transactionDate = (data[fieldName] as Timestamp).toDate();
              break;
            } else if (data[fieldName] is String) {
              try {
                transactionDate = DateTime.parse(data[fieldName]);
                break;
              } catch (_) {}
            }
          }
        }
        
        // Skip if we can't determine the date
        if (transactionDate == null) continue;
        
        // Extract amount
        num amount = 0;
        for (var fieldName in ['totalAmount', 'Amount', 'amount', 'total']) {
          if (data[fieldName] != null) {
            // Handle different numeric formats
            if (data[fieldName] is num) {
              amount = data[fieldName];
              break;
            } else if (data[fieldName] is String) {
              try {
                amount = num.parse(data[fieldName]);
                break;
              } catch (_) {}
            }
          }
        }
        
        // Add to appropriate time periods
        if (transactionDate.isAfter(today) || 
            transactionDate.year == today.year && 
            transactionDate.month == today.month && 
            transactionDate.day == today.day) {
          todaySales += amount.toDouble();
        }
        
        if (transactionDate.isAfter(weekStart) || 
            (transactionDate.year == weekStart.year && 
             transactionDate.month == weekStart.month && 
             transactionDate.day == weekStart.day)) {
          weekSales += amount.toDouble();
        }
        
        if (transactionDate.isAfter(monthStart) || 
            (transactionDate.year == monthStart.year && 
             transactionDate.month == monthStart.month && 
             transactionDate.day == monthStart.day)) {
          monthSales += amount.toDouble();
          
          // Count total items sold this month
          if (data['items'] != null && data['items'] is List) {
            for (var item in data['items']) {
              if (item is Map) {
                int quantity = 1;
                if (item['quantity'] != null) {
                  if (item['quantity'] is int) {
                    quantity = item['quantity'];
                  } else if (item['quantity'] is String) {
                    try {
                      quantity = int.parse(item['quantity']);
                    } catch (_) {}
                  }
                }
                totalItems += quantity;
              }
            }
          }
        }
      }
      
      if (mounted) {
        setState(() {
          salesStats = {
            'todaySales': todaySales,
            'weekSales': weekSales,
            'monthSales': monthSales,
            'totalItems': totalItems,
          };
        });
      }
    } catch (e) {
      print('Error fetching sales stats: $e');
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
      backgroundColor: Colors.grey[100],
      appBar: MyAppBar(pageinfo: 'Dukaan Diary'),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _fetchRecentTransactions(),
            _fetchSalesStats(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sales Overview Card
                _buildSalesOverviewCard(),
                
                const SizedBox(height: 20),
                
                // Period Sales Cards
                _buildSalesPeriodCards(),
                
                const SizedBox(height: 20),
                
                // Action buttons row (removed inventory button)
                _buildActionButtonsRow(),
                
                const SizedBox(height: 20),
                
                // Recent Transactions Section
                _buildRecentTransactionsSection(),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      // Adding a floating action button for quick access
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.purple.shade700,
        icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
        label: const Text('New Sale', style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.pushNamed(context, '/add_transaction_page').then((_) {
            // Refresh data when returning from add transaction page
            _fetchRecentTransactions();
            _fetchSalesStats();
          });
        },
      ),
    );
  }
  
  Widget _buildSalesOverviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade800, Colors.indigo.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Sales Overview",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "This Month",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _formatCurrency(salesStats['monthSales']),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(
                Icons.arrow_upward,
                color: Colors.greenAccent,
                size: 16,
              ),
              Text(
                salesStats['monthSales'] > 0 
                    ? " ${((salesStats['weekSales'] / salesStats['monthSales']) * 100).toStringAsFixed(1)}% from last week"
                    : " 0% from last week",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.greenAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSalesStatItem(
                "Today",
                _formatCurrency(salesStats['todaySales']),
                Colors.orangeAccent,
              ),
              _buildSalesStatItem(
                "This Week",
                _formatCurrency(salesStats['weekSales']),
                Colors.greenAccent,
              ),
              _buildSalesStatItem(
                "Items Sold",
                salesStats['totalItems'].toString(),
                Colors.cyanAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSalesStatItem(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSalesPeriodCards() {
    return Row(
      children: [
        Expanded(
          child: _buildGradientCard(
            title: "Today's Sales",
            value: _formatCurrency(salesStats['todaySales']),
            icon: Icons.today,
            color1: Colors.blue.shade700,
            color2: Colors.blue.shade500,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildGradientCard(
            title: "Weekly Sales",
            value: _formatCurrency(salesStats['weekSales']),
            icon: Icons.calendar_view_week,
            color1: Colors.purple.shade700,
            color2: Colors.purple.shade500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildGradientCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color1,
    required Color color2,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color1.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtonsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // View All Transactions Button
        Expanded(
          child: _buildActionButton(
            icon: Icons.history,
            label: 'Transactions',
            color: Colors.blue.shade700,
            onTap: () => Navigator.pushNamed(context, '/history_page').then((_) {
              // Refresh data when returning from history page
              _fetchRecentTransactions();
              _fetchSalesStats();
            }),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Analytics Button
        Expanded(
          child: _buildActionButton(
            icon: Icons.bar_chart,
            label: 'Analytics',
            color: Colors.green.shade600,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionAnalyticsPage(),
                ),
              ).then((_) {
                // Refresh data when returning from analytics page
                _fetchRecentTransactions();
                _fetchSalesStats();
              });
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecentTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Recent Transactions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/history_page');
              },
              child: Text(
                "View All",
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        errorMessage,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                : recentTransactions.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No transactions yet",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/add_transaction_page');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple.shade700,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text("Add Your First Sale"),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _buildTransactionsList(),
      ],
    );
  }
  
  Widget _buildTransactionsList() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: recentTransactions.length,
        separatorBuilder: (context, index) => Divider(
          color: Colors.grey.shade200,
          height: 1,
        ),
        itemBuilder: (context, index) {
          final transaction = recentTransactions[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionDetailPage(
                    transactionId: transaction['id'],
                  ),
                ),
              ).then((_) {
                _fetchRecentTransactions();
                _fetchSalesStats();
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              child: Row(
                children: [
                  // Transaction icon with colored background
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.shopping_bag,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Transaction details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                transaction['product'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              _formatCurrency(transaction['amount']),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              transaction['customer'],
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              DateFormat('dd MMM, h:mm a').format(transaction['date']),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (transaction['transactionNumber'] != null && 
                            transaction['transactionNumber'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              "# ${transaction['transactionNumber']}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Helper function for max()
double max(double a, double b) {
  return a > b ? a : b;
}