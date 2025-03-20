import 'package:dukaan_diary/components/input_field.dart';
import 'package:dukaan_diary/components/my_app_bar.dart';
import 'package:flutter/material.dart';

class AddProductPage extends StatelessWidget {
  final product_name_controller = TextEditingController();
  final product_number_controller = TextEditingController();
  final product_description_controller = TextEditingController();
  AddProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(shopname: 'Shop name', pageinfo: 'Add Products'),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 25),
            MyInputField(
              heading: 'Product Name',
              controller: product_name_controller,
              hintText: 'Enter Your Product Name',
            ),
            MyInputField(
              heading: 'Product Number',
              controller: product_number_controller,
              hintText: 'Enter Your Product Number',
            ),
            Padding(
              padding: const EdgeInsets.only(top: 25.0),
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  padding: EdgeInsets.all(8),
                  margin: EdgeInsets.symmetric(horizontal: 125),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade300,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline_rounded, size: 25),
                      Text('Add Items', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 25.0),
              child: Container(
                padding: EdgeInsets.all(25),
                color: Colors.blue[200],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 25),
                      decoration: BoxDecoration(color: Colors.white),
                      child: Text(
                        '5000',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            MyInputField(
              heading: 'Description',
              controller: product_description_controller,
              hintText: 'Enter Any Note',
            ),
            Padding(
              padding: const EdgeInsets.only(top: 50.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 25),
                      decoration: BoxDecoration(color: Colors.blue),
                      child: Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 25),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 25),
                      decoration: BoxDecoration(color: Colors.red),
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
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
  }
}
