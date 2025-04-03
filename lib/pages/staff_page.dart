import 'package:dukaan_diary/components/my_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool isLoading = false;
  late Stream<QuerySnapshot> _employeesStream;

  @override
  void initState() {
    super.initState();
    // Print user ID for debugging
    print("Current user ID: ${user?.uid}");
    
    // Initialize the stream
    _initEmployeesStream();
    
    // Force a refresh after a short delay
    Future.delayed(Duration.zero, () {
      if (mounted) setState(() {});
    });
  }

  void _initEmployeesStream() {
    if (user != null) {
      _employeesStream = FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .collection("employees")
          .orderBy("name")
          .snapshots();
          
      // Debug: Listen to stream events
      _employeesStream.listen(
        (snapshot) {
          print("Stream update: ${snapshot.docs.length} employees found");
          if (snapshot.docs.isNotEmpty) {
            print("First employee data: ${snapshot.docs[0].data()}");
          }
        },
        onError: (error) => print("Stream error: $error"),
      );
    }
  }

  Future<void> _deleteEmployee(String employeeId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this employee?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      setState(() {
        isLoading = true;
      });

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .collection("employees")
          .doc(employeeId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Employee deleted successfully!")),
      );
    } catch (e) {
      print("Error deleting employee: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting employee: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _navigateToAddEmployee(BuildContext context, [String? employeeId]) async {
    final result = await Navigator.pushNamed(
      context,
      '/add_employee',
      arguments: employeeId,
    );
    
    if (result == true) {
      // Refresh the UI - Firebase stream should handle this automatically
      // but forcing a refresh here might help
      if (mounted) {
        setState(() {
          // Re-initialize the stream to ensure fresh data
          _initEmployeesStream();
        });
      }
    }
  }

  String _formatDate(Timestamp timestamp) {
    final DateTime date = timestamp.toDate();
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Widget _buildEmployeeList() {
    if (user == null) {
      return const Center(child: Text("Please sign in to view staff members"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _employeesStream,
      builder: (context, snapshot) {
        // Debug prints
        print("StreamBuilder connection state: ${snapshot.connectionState}");
        print("Has error: ${snapshot.hasError}");
        print("Has data: ${snapshot.hasData}");
        if (snapshot.hasData) {
          print("Docs count: ${snapshot.data!.docs.length}");
        }
        
        if (snapshot.connectionState == ConnectionState.waiting || isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print("StreamBuilder error: ${snapshot.error}");
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  "No staff members yet",
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Add your first employee using the + button",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // If we get here, we have data to display
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final employeeData = doc.data() as Map<String, dynamic>;
            final employeeId = doc.id;
            
            // Debug print for this specific employee
            print("Building UI for employee: $employeeId with data: $employeeData");
            
            final name = employeeData['name'] ?? 'Unknown';
            final status = employeeData['employeeStatus'] ?? 'Active';
            
            // Handle salary safely - could be stored as double, int, or string
            var salary = 0.0;
            if (employeeData['salary'] != null) {
              if (employeeData['salary'] is double) {
                salary = employeeData['salary'];
              } else if (employeeData['salary'] is int) {
                salary = (employeeData['salary'] as int).toDouble();
              } else if (employeeData['salary'] is String) {
                salary = double.tryParse(employeeData['salary']) ?? 0.0;
              }
            }
            
            // Handle joining date safely
            String joiningDate = 'Unknown';
            if (employeeData['joiningDate'] != null) {
              if (employeeData['joiningDate'] is Timestamp) {
                joiningDate = _formatDate(employeeData['joiningDate'] as Timestamp);
              } else {
                // Try to handle other date formats if needed
                print("joiningDate is not a Timestamp: ${employeeData['joiningDate']}");
              }
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: status == 'Active' ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status,
                          style: TextStyle(
                            color: status == 'Active' ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text("Joined: $joiningDate"),
                    const SizedBox(height: 4),
                    Text(
                      "Salary: ₹${salary.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _navigateToAddEmployee(context, employeeId),
                      tooltip: 'Edit Employee',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteEmployee(employeeId),
                      tooltip: 'Delete Employee',
                    ),
                  ],
                ),
                // onTap: () => _navigateToAddEmployee(context, employeeId),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar(pageinfo: 'Staff Members'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Manage your staff members",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
          // Show loading indicator if still loading
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Force UI refresh on pull-to-refresh
                  setState(() {
                    _initEmployeesStream();
                  });
                },
                child: _buildEmployeeList(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEmployee(context),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Employee',
      ),
    );
  }
  
  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }
}