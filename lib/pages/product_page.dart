import 'package:dukaan_diary/components/my_app_bar.dart';
import 'package:flutter/material.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  List<Map<String, dynamic>> products = [
    {
      "name": "Laptop",
      "number": "P001",
      "price": 50000,
      "quantity": 2,
      "description": "Gaming Laptop",
    },
    {
      "name": "Phone",
      "number": "P002",
      "price": 20000,
      "quantity": 3,
      "description": "Android Smartphone",
    },
    {
      "name": "Tablet",
      "number": "P003",
      "price": 15000,
      "quantity": 5,
      "description": "Portable Tablet",
    },
  ];

  void _deleteProduct(int index) {
    setState(() {
      products.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(shopname: 'Shop Name', pageinfo: 'Product List'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add_product_page'),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          var product = products[index];
          return Dismissible(
            key: Key(product['number']),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) => _deleteProduct(index),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.shopping_bag,
                  color: Colors.blue,
                  size: 30,
                ),
                title: Text(
                  product['name'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Product Number: ${product['number']}"),
                    Text("Price per Unit: ₹${product['price']}"),
                    Text("Quantity: ${product['quantity']}"),
                    Text(
                      "Total Price: ₹${product['price'] * product['quantity']}",
                    ),
                    Text(
                      "Description: ${product['description']}",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
