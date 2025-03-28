import 'package:dukaan_diary/components/my_app_bar.dart';
import 'package:flutter/material.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController productNumberController = TextEditingController();
  final TextEditingController productPriceController = TextEditingController();
  final TextEditingController productQuantityController =
      TextEditingController();
  final TextEditingController productDescriptionController =
      TextEditingController();
  double totalPrice = 0;

  void _calculateTotal() {
    double price = double.tryParse(productPriceController.text) ?? 0;
    int quantity = int.tryParse(productQuantityController.text) ?? 0;
    setState(() {
      totalPrice = price * quantity;
    });
  }

  void _saveProduct() {
    String name = productNameController.text;
    String number = productNumberController.text;
    String description = productDescriptionController.text;
    if (name.isNotEmpty && number.isNotEmpty && totalPrice > 0) {
      print(
        "Product Saved: $name, No: $number, Total Price: ₹$totalPrice, Description: $description",
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid details!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(shopname: 'Shop Name', pageinfo: 'Add Product'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: productNameController,
                decoration: const InputDecoration(labelText: "Product Name"),
              ),
              TextField(
                controller: productNumberController,
                decoration: const InputDecoration(labelText: "Product Number"),
              ),
              TextField(
                controller: productPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Price per Unit"),
                onChanged: (val) => _calculateTotal(),
              ),
              TextField(
                controller: productQuantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Quantity"),
                onChanged: (val) => _calculateTotal(),
              ),
              TextField(
                controller: productDescriptionController,
                decoration: const InputDecoration(
                  labelText: "Product Description",
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Price:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹$totalPrice',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _saveProduct,
                    child: const Text("Save"),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text("Cancel"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
