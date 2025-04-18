import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dukaan_diary/components/my_app_bar.dart';

class TransactionAnalyticsPage extends StatefulWidget {
  const TransactionAnalyticsPage({super.key});

  @override
  State<TransactionAnalyticsPage> createState() => _TransactionAnalyticsPageState();
}

class _TransactionAnalyticsPageState extends State<TransactionAnalyticsPage> {
  bool isLoading = true;
  String errorMessage = '';
  
  // Daily transaction data
  List<FlSpot> dailySpots = [];
  double maxDailyAmount = 0;
  
  // Product distribution data
  Map<String, double> productDistribution = {};
  
  // Monthly transaction data
  Map<int, double> monthlyData = {};
  
  // Total sales amount
  double totalSalesAmount = 0;
  
  // Transaction count
  int transactionCount = 0;
  
  // Selected time period
  String selectedPeriod = 'Week'; // Default to Week
  final List<String> periods = ['Week', 'Month', 'Year'];
  
  @override
  void initState() {
    super.initState();
    _fetchTransactionData();
  }
  
  Future<void> _fetchTransactionData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        setState(() {
          errorMessage = 'You must be logged in to view analytics';
          isLoading = false;
        });
        return;
      }
      
      // Calculate date range based on selected period
      DateTime endDate = DateTime.now();
      DateTime startDate;
      
      switch (selectedPeriod) {
        case 'Week':
          startDate = endDate.subtract(const Duration(days: 8));
          break;
        case 'Month':
          startDate = DateTime(endDate.year, endDate.month - 1, endDate.day);
          break;
        case 'Year':
          startDate = DateTime(endDate.year - 1, endDate.month, endDate.day);
          break;
        default:
          startDate = endDate.subtract(const Duration(days: 7));
      }
      
      // Query Firestore for transactions in the date range
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: currentUser.uid)
          .where('Datetime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('Datetime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('Datetime', descending: false)
          .get()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Connection timeout. Please check your internet connection.');
            },
          );
      
      // Process data for charts
      _processChartData(snapshot.docs, startDate, endDate);
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching transaction data: ${e.toString()}';
        isLoading = false;
      });
    }
  }
  
  void _processChartData(List<QueryDocumentSnapshot> docs, DateTime startDate, DateTime endDate) {
    // Reset data
    dailySpots = [];
    productDistribution = {};
    monthlyData = {};
    maxDailyAmount = 0;
    totalSalesAmount = 0;
    transactionCount = docs.length;
    
    // Group transactions by date
    Map<String, double> dailyTotals = {};
    
    // Process each transaction
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Safely extract amount
      final double amount;
      try {
        amount = (data['Amount'] is num)
            ? (data['Amount'] as num).toDouble()
            : double.tryParse(data['Amount'].toString()) ?? 0.0;
      } catch (e) {
        // Skip invalid amount entries
        continue;
      }
      
      final product = data['productname'] ?? 'Unknown Product';
      
      // Get transaction date
      final DateTime transactionDate;
      try {
         transactionDate = data['Datetime'] is Timestamp
      ? (data['Datetime'] as Timestamp).toDate()
      : DateTime.tryParse(data['Datetime'].toString()) ?? DateTime.now();
  
      print('Processing transaction from: ${transactionDate.toString()}');
      } catch (e) {
        // Skip invalid date entries
        continue;
      }
      
      // Update total sales amount
      totalSalesAmount += amount;
      
      // For daily chart
      final String dateKey = DateFormat('yyyy-MM-dd').format(transactionDate);
      dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + amount;
      
      // For product distribution
      productDistribution[product] = (productDistribution[product] ?? 0) + amount;
      
      // For monthly data
      final int monthKey = transactionDate.month;
      monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + amount;
    }
    
    // Convert daily totals to FlSpot points
    int daysDifference = endDate.difference(startDate).inDays;
    
    for (int i = 0; i <= daysDifference; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final amount = dailyTotals[dateKey] ?? 0;
      
      // X-axis is the day index, Y-axis is the amount
      dailySpots.add(FlSpot(i.toDouble(), amount));
      
      // Track max amount for Y-axis scaling
      if (amount > maxDailyAmount) {
        maxDailyAmount = amount;
      }
    }

    // If no data was found, add a zero point to avoid empty chart errors
    if (dailySpots.isEmpty) {
      dailySpots.add(const FlSpot(0, 0));
    }
    
    // Sort product distribution by value for better visualization
    final sortedProducts = productDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Keep only top 5 products and group others as "Others"
    if (sortedProducts.length > 5) {
      double othersTotal = 0;
      for (int i = 5; i < sortedProducts.length; i++) {
        othersTotal += sortedProducts[i].value;
      }
      
      // Create a new map with top 5 products
      Map<String, double> topProducts = {
        for (int i = 0; i < 5 && i < sortedProducts.length; i++) 
          sortedProducts[i].key: sortedProducts[i].value
      };
      
      if (othersTotal > 0) {
        topProducts['Others'] = othersTotal;
      }
      
      // Replace product distribution with our filtered version
      productDistribution = topProducts;
    }
  }

  // Helper function to format currency
  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(pageinfo: 'Transaction Analytics'),
      backgroundColor: Colors.grey[100],
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : errorMessage.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage, 
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _fetchTransactionData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchTransactionData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time period selector
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Time Period',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: periods.map((period) => 
                                ChoiceChip(
                                  label: Text(period),
                                  selected: selectedPeriod == period,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        selectedPeriod = period;
                                      });
                                      _fetchTransactionData();
                                    }
                                  },
                                )
                              ).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Summary cards
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Sales',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatCurrency(totalSalesAmount),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Transactions',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    transactionCount.toString(),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Sales trend chart
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sales Trend',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Last $selectedPeriod',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 24),
                            dailySpots.isEmpty || dailySpots.length == 1 && dailySpots[0].y == 0
                              ? SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No transaction data available',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : SizedBox(
                                height: 200,
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: maxDailyAmount > 0 ? maxDailyAmount / 4 : 250, 
                                      getDrawingHorizontalLine: (value) => FlLine(
                                        color: Colors.grey[300],
                                        strokeWidth: 1,
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                          getTitlesWidget: (value, meta) {
                                            if (value == 0) {
                                              return const Text('₹0');
                                            }
                                            if (maxDailyAmount > 0 && (value == maxDailyAmount || 
                                                value == maxDailyAmount / 2)) {
                                              return Text('₹${value.toInt()}');
                                            }
                                            return const Text('');
                                          },
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          getTitlesWidget: (value, meta) {
                                            // Show only a few strategic dates for better readability
                                            if (dailySpots.isNotEmpty) {
                                              final numPoints = dailySpots.length - 1;
                                              if (value == 0 || value == numPoints || 
                                                  (numPoints > 2 && value == numPoints / 2)) {
                                                final date = DateTime.now().subtract(
                                                  Duration(days: (numPoints - value.toInt()))
                                                );
                                                return Padding(
                                                  padding: const EdgeInsets.only(top: 8.0),
                                                  child: Text(DateFormat('dd/MM').format(date)),
                                                );
                                              }
                                            }
                                            return const Text('');
                                          },
                                        ),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border(
                                        left: BorderSide(color: Colors.grey[300]!),
                                        bottom: BorderSide(color: Colors.grey[300]!),
                                      ),
                                    ),
                                    minX: 0,
                                    maxX: dailySpots.length - 1.0,
                                    minY: 0,
                                    maxY: maxDailyAmount > 0 ? maxDailyAmount * 1.2 : 1000,
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: dailySpots,
                                        isCurved: true,
                                        gradient: const LinearGradient(
                                          colors: [Colors.blue, Colors.lightBlueAccent],
                                        ),
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        dotData: FlDotData(
                                          show: dailySpots.length < 15, // Only show dots if few data points
                                          getDotPainter: (spot, percent, barData, index) => 
                                            FlDotCirclePainter(
                                              radius: 4,
                                              color: Colors.white,
                                              strokeWidth: 2,
                                              strokeColor: Colors.blue,
                                            ),
                                        ),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.blue.withOpacity(0.3),
                                              Colors.blue.withOpacity(0.1),
                                              Colors.blue.withOpacity(0.0),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Product distribution
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Product Distribution',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            productDistribution.isEmpty
                              ? SizedBox(
                                  height: 150,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.pie_chart, size: 48, color: Colors.grey[400]),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No product data available',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Column(
                                  children: productDistribution.entries.map((entry) {
                                    // Calculate percentage of total
                                    final total = productDistribution.values.reduce((a, b) => a + b);
                                    final percentage = (entry.value / total * 100).toStringAsFixed(1);
                                    
                                    // Generate a consistent color based on the product name
                                    final int colorValue = entry.key.hashCode;
                                    final Color barColor = entry.key == 'Others' 
                                      ? Colors.grey 
                                      : Color(0xFF000000 | (colorValue & 0x00FFFFFF)).withOpacity(0.8);
                                    
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  entry.key,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 16),
                                                ),
                                              ),
                                              Text(
                                                '${_formatCurrency(entry.value)} ($percentage%)',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          LinearProgressIndicator(
                                            value: entry.value / total,
                                            backgroundColor: Colors.grey[200],
                                            color: barColor,
                                            minHeight: 10,
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16), 
                    
                    // Monthly Summary
                    if (selectedPeriod == 'Year')
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Monthly Summary',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              monthlyData.isEmpty
                                ? SizedBox(
                                    height: 150,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No monthly data available',
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : SizedBox(
                                  height: 250,
                                  child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY: monthlyData.values.isEmpty ? 
                                        1000 : 
                                        monthlyData.values.reduce((a, b) => a > b ? a : b) * 1.2,
                                      gridData: FlGridData(
                                        show: true,
                                        horizontalInterval: monthlyData.values.isEmpty ? 
                                          200 : 
                                          monthlyData.values.reduce((a, b) => a > b ? a : b) / 5,
                                        getDrawingHorizontalLine: (value) => FlLine(
                                          color: Colors.grey[300],
                                          strokeWidth: 1,
                                        ),
                                        drawVerticalLine: false,
                                      ),
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(
                                          axisNameWidget: const Padding(
                                            padding: EdgeInsets.only(right: 8.0),
                                            child: Text('Amount (₹)'),
                                          ),
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 50,
                                            getTitlesWidget: (value, meta) {
                                              if (value == 0) return const Text('₹0');
                                              
                                              // Format numbers over 1000 as 1k, 10k, etc.
                                              if (value >= 1000) {
                                                return Text('₹${(value/1000).toStringAsFixed(0)}k');
                                              }
                                              
                                              return Text('₹${value.toInt()}');
                                            },
                                          ),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 30,
                                            getTitlesWidget: (value, meta) {
                                              final List<String> months = [
                                                'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                                              ];
                                              if (value >= 0 && value < months.length) {
                                                return Padding(
                                                  padding: const EdgeInsets.only(top: 8.0),
                                                  child: Text(months[value.toInt()]),
                                                );
                                              }
                                              return const Text('');
                                            },
                                          ),
                                        ),
                                        rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                        topTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                      ),
                                      borderData: FlBorderData(
                                        show: true,
                                        border: Border(
                                          left: BorderSide(color: Colors.grey[300]!),
                                          bottom: BorderSide(color: Colors.grey[300]!),
                                        ),
                                      ),
                                      barGroups: List.generate(12, (monthIndex) {
                                        final monthValue = monthlyData[monthIndex + 1] ?? 0;
                                        
                                        return BarChartGroupData(
                                          x: monthIndex,
                                          barRods: [
                                            BarChartRodData(
                                              toY: monthValue,
                                              gradient: const LinearGradient(
                                                colors: [Colors.blueAccent, Colors.blue],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                              width: 16,
                                              borderRadius: const BorderRadius.only(
                                                topLeft: Radius.circular(4),
                                                topRight: Radius.circular(4),
                                              ),
                                              backDrawRodData: BackgroundBarChartRodData(
                                                show: true,
                                                toY: monthlyData.values.isEmpty ? 
                                                  1000 : 
                                                  monthlyData.values.reduce((a, b) => a > b ? a : b) * 1.2,
                                                color: Colors.grey[200],
                                              ),
                                            ),
                                          ],
                                        );
                                      }),
                                      barTouchData: BarTouchData(
                                        touchTooltipData: BarTouchTooltipData(
                                          // tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                                          tooltipPadding: const EdgeInsets.all(8),
                                          
                                          tooltipMargin: 8,
                                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                            final List<String> months = [
                                              'January', 'February', 'March', 'April', 'May', 'June',
                                              'July', 'August', 'September', 'October', 'November', 'December'
                                            ];
                                            final String month = months[group.x];
                                            final double value = rod.toY;
                                            return BarTooltipItem(
                                              '$month\n${_formatCurrency(value)}',
                                              const TextStyle(color: Colors.white),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}

// Custom TimeoutException class
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}