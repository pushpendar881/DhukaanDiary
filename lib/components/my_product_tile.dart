import 'package:flutter/material.dart';

class MyProductTile extends StatelessWidget {
  const MyProductTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: 3,
      itemBuilder: (context, index) {
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.production_quantity_limits_rounded,
                  color: Colors.black,
                ),
                title: Text(
                  'Product Name',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Product Quantity:',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
