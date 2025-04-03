import 'package:flutter/material.dart';
import 'package:dukaan_diary/components/my_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEmployeePage extends StatefulWidget {
  final String? employeeId;
  const AddEmployeePage({super.key, this.employeeId});

  @override
  State<AddEmployeePage> createState() => _AddEmployeePageState();
}

class _AddEmployeePageState extends State<AddEmployeePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController salaryController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  String employeeStatus = 'Active';
  bool isLoading = false;

  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (widget.employeeId != null) {
      _loadEmployeeData();
    }
  }

  Future<void> _loadEmployeeData() async {
    if (user == null) return;
    
    setState(() {
      isLoading = true;
    });
    
    try {
      DocumentSnapshot employeeDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .collection("employees")
          .doc(widget.employeeId)
          .get();
          
      if (employeeDoc.exists) {
        Map<String, dynamic> data = employeeDoc.data() as Map<String, dynamic>;
        nameController.text = data['name'] ?? '';
        salaryController.text = data['salary']?.toString() ?? '';
        contactController.text = data['contact'] ?? '';
        addressController.text = data['address'] ?? '';
        
        if (data['joiningDate'] != null) {
          selectedDate = (data['joiningDate'] as Timestamp).toDate();
        }
        
        employeeStatus = data['employeeStatus'] ?? 'Active';
        setState(() {});
      }
    } catch (e) {
      print("Error loading employee data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading employee data: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveEmployee() async {
    String name = nameController.text.trim();
    String salaryText = salaryController.text.trim();
    String contact = contactController.text.trim();
    String address = addressController.text.trim();
    
    // Validation
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter employee name")),
      );
      return;
    }
    
    double? salary = double.tryParse(salaryText);
    if (salary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid salary")),
      );
      return;
    }
    
    setState(() {
      isLoading = true;
    });
    
    try {
      if (user == null) {
        throw Exception("User not authenticated");
      }
      
      final employeeData = {
        'name': name,
        'salary': salary,
        'contact': contact,
        'address': address,
        'joiningDate': Timestamp.fromDate(selectedDate),
        'employeeStatus': employeeStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (widget.employeeId == null) {
        // Adding a new employee
        employeeData['createdAt'] = FieldValue.serverTimestamp();
        
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user!.uid)
            .collection("employees")
            .add(employeeData);
            
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Employee added successfully!")),
        );
      } else {
        // Updating existing employee
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user!.uid)
            .collection("employees")
            .doc(widget.employeeId)
            .update(employeeData);
            
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Employee updated successfully!")),
        );
      }
      
      Navigator.pop(context, true);
    } catch (e) {
      print("Error saving employee: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving employee: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(pageinfo: widget.employeeId == null ? 'Add Employee' : 'Edit Employee'),
      backgroundColor: Colors.white,
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Employee Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: salaryController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Salary",
                    border: OutlineInputBorder(),
                    prefixText: "₹ ",
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contactController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Contact Number",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: "Address",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  child: ListTile(
                    title: Text("Joining Date: ${selectedDate.toLocal().toString().split(' ')[0]}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null && pickedDate != selectedDate) {
                          setState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: employeeStatus,
                  onChanged: (newValue) => setState(() => employeeStatus = newValue!),
                  items: ["Active", "Inactive"].map((status) {
                    return DropdownMenuItem(value: status, child: Text(status));
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: "Employee Status",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveEmployee,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(widget.employeeId == null ? "Add Employee" : "Update Employee"),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}