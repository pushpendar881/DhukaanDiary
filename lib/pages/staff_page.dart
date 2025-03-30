import 'package:dukaan_diary/components/my_app_bar.dart';
import 'package:flutter/material.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  List<Map<String, dynamic>> staffList = [
    {"name": "Ramesh", "status": "Active", "joiningDate": "2023-05-10"},
    {"name": "Suresh", "status": "Inactive", "joiningDate": "2022-11-15"},
    {"name": "Mahesh", "status": "Active", "joiningDate": "2024-01-20"},
  ];

  void _editEmployee(int index) {
    // Placeholder function for editing
    print("Editing: ${staffList[index]['name']}");
  }

  void _deleteEmployee(int index) {
    setState(() {
      staffList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar( pageinfo: 'Staff Members'),
      body: ListView.builder(
        itemCount: staffList.length,
        itemBuilder: (context, index) {
          var staff = staffList[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              title: Text(staff['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Status: ${staff['status']}",
                      style: TextStyle(color: staff['status'] == 'Active' ? Colors.green : Colors.red)),
                  Text("Joining Date: ${staff['joiningDate']}"),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editEmployee(index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteEmployee(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add_employee'); // Redirects to add employee page
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}