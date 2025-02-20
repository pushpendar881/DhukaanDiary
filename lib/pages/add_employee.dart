import 'package:dukaan_diary/components/input_field.dart';
import 'package:flutter/material.dart';

class AddEmployee extends StatefulWidget {
  const AddEmployee({super.key});

  @override
  State<AddEmployee> createState() => _AddEmployeeState();
}

class _AddEmployeeState extends State<AddEmployee> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Add Staff", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        toolbarHeight: 90,
        backgroundColor: Colors.blue[900],
        elevation: 10,
        shadowColor: Colors.black,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            MyInputField(
              //Name
              heading: "Name",
              hintText: "Employee Name",
              controller: _nameController,
            ),

            //Shop name
            MyInputField(
              heading: "Salary",
              hintText: "Enter salary",
              controller: _salaryController,
            ),

            //Address
            MyInputField(
              heading: "Contact Number",
              hintText: "Phone number",
              controller: _contactController,
            ),

            //
          ],
        ),
      ),
    );
  }
}
