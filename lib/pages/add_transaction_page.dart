import 'package:flutter/material.dart';
import 'package:dukaan_diary/components/my_app_bar.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController productNumberController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController customerNameController = TextEditingController(
    text: "Customer",
  );
  double totalAmount = 0;
  DateTime selectedDate = DateTime.now();

  void _calculateTotal() {
    double pricePerUnit = 500; // Placeholder for fetched price from backend
    int quantity = int.tryParse(quantityController.text) ?? 0;
    setState(() {
      totalAmount = pricePerUnit * quantity;
    });
  }

  void _saveTransaction() {
    String product = productNameController.text;
    String number = productNumberController.text;
    String customer = customerNameController.text;
    if (product.isNotEmpty && number.isNotEmpty && totalAmount > 0) {
      print(
        "Transaction Saved: $product, $number, Quantity: ${quantityController.text}, Total: ₹$totalAmount, Customer: $customer",
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
      appBar: MyAppBar(
        
        pageinfo: 'Add Sales Transaction',
      ),
      backgroundColor: Colors.white,
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
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Quantity Sold"),
                onChanged: (val) => _calculateTotal(),
              ),
              TextField(
                controller: customerNameController,
                decoration: const InputDecoration(
                  labelText: "Customer Name (Optional)",
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
                        'Total Amount:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹$totalAmount',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ListTile(
                title: Text(
                  "Date: ${selectedDate.toLocal().toString().split(' ')[0]}",
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2023),
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
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _saveTransaction,
                    child: const Text("Save"),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
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
