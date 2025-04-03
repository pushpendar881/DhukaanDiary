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
          startDate = endDate.subtract(const Duration(days: 7));
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
          .get();
      
      // Process data for charts
      _processChartData(snapshot.docs, startDate, endDate);
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching transaction data: $e';
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
    
    // Group transactions by date
    Map<String, double> dailyTotals = {};
    
    // Process each transaction
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['Amount'] ?? 0).toDouble();
      final product = data['productname'] ?? 'Unknown Product';
      
      // Get transaction date
      final DateTime transactionDate = data['Datetime'] is Timestamp
          ? (data['Datetime'] as Timestamp).toDate()
          : DateTime.now();
      
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
      
      productDistribution = {
        for (int i = 0; i < 5; i++) 
          sortedProducts[i].key: sortedProducts[i].value
      };
      
      if (othersTotal > 0) {
        productDistribution['Others'] = othersTotal;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(pageinfo: 'Transaction Analytics'),
      backgroundColor: Colors.grey[100],
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)))
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
                            SizedBox(
                              height: 200,
                              child: dailySpots.isEmpty 
                                ? const Center(child: Text('No transaction data available'))
                                : LineChart(
                                    LineChartData(
                                      gridData: FlGridData(show: false),
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40,
                                            getTitlesWidget: (value, meta) {
                                              if (value == 0) {
                                                return const Text('₹0');
                                              }
                                              if (maxDailyAmount > 0 && value == maxDailyAmount) {
                                                return Text('₹${value.toInt()}');
                                              }
                                              if (value == maxDailyAmount / 2) {
                                                return Text('₹${(value).toInt()}');
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
                                                if (value == 0 || value == dailySpots.length - 1 || 
                                                    value == (dailySpots.length - 1) / 2) {
                                                  final date = DateTime.now().subtract(
                                                    Duration(days: (dailySpots.length - 1 - value.toInt()))
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
                                      borderData: FlBorderData(show: false),
                                      minX: 0,
                                      maxX: dailySpots.length - 1.0,
                                      minY: 0,
                                      maxY: maxDailyAmount > 0 ? maxDailyAmount * 1.2 : 1000,
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: dailySpots,
                                          isCurved: true,
                                          color: Colors.blue,
                                          barWidth: 3,
                                          isStrokeCapRound: true,
                                          dotData: const FlDotData(show: false),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            color: Colors.blue.withOpacity(0.2),
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
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text('No product data available'),
                                  ),
                                )
                              : Column(
                                  children: productDistribution.entries.map((entry) {
                                    // Calculate percentage of total
                                    final total = productDistribution.values.reduce((a, b) => a + b);
                                    final percentage = (entry.value / total * 100).toStringAsFixed(1);
                                    
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
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
                                                '₹${entry.value.toStringAsFixed(2)} ($percentage%)',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          LinearProgressIndicator(
                                            value: entry.value / total,
                                            backgroundColor: Colors.grey[200],
                                            color: Colors.blue,
                                            minHeight: 8,
                                            borderRadius: BorderRadius.circular(4),
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
                    if (selectedPeriod == 'Year' && monthlyData.isNotEmpty)
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
                              SizedBox(
                                height: 200,
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
                                        axisNameWidget: const Text('Amount (₹)'),
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                          getTitlesWidget: (value, meta) {
                                            return value % 1000 == 0 ? 
                                              Text('₹${value.toInt()}') : 
                                              const Text('');
                                          },
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final List<String> months = [
                                              'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                                            ];
                                            if (value >= 0 && value < months.length) {
                                              return Text(months[value.toInt()]);
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
                                    borderData: FlBorderData(show: false),
                                    barGroups: monthlyData.entries.map((entry) {
                                      return BarChartGroupData(
                                        x: entry.key - 1, // Month index (0-11)
                                        barRods: [
                                          BarChartRodData(
                                            toY: entry.value,
                                            color: Colors.blue,
                                            width: 16,
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(4),
                                              topRight: Radius.circular(4),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
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