import 'package:flutter/material.dart';
import 'package:dukaan_diary/components/my_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddTransactionPage extends StatefulWidget {
  final String? transactionId;

  const AddTransactionPage({super.key, this.transactionId});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController productNumberController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController customerNameController = TextEditingController(text: "Customer");
  
  double pricePerUnit = 0;
  double totalAmount = 0;
  DateTime selectedDate = DateTime.now();
  String? originalProductNumber;
  int? originalQuantity;
  String? selectedProductId;

  bool isLoading = false;
  final User? user = FirebaseAuth.instance.currentUser;
  
  @override
  void initState() {
    super.initState();
    if (widget.transactionId != null) {
      _loadTransactionData();
    }
  }

  @override
  void dispose() {
    // Clean up controllers to avoid memory leaks
    productNameController.dispose();
    productNumberController.dispose();
    quantityController.dispose();
    customerNameController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactionData() async {
    if (user == null || widget.transactionId == null) return;
    
    setState(() => isLoading = true);
    
    try {
      final DocumentSnapshot transactionSnapshot = await FirebaseFirestore.instance
          .collection("transactions")
          .doc(widget.transactionId)
          .get();

      if (transactionSnapshot.exists) {
        final data = transactionSnapshot.data() as Map<String, dynamic>;
        
        // Store original product number for inventory restoration later
        originalProductNumber = data['productnumber'];
        
        // Parse quantity regardless of type
        if (data['productQuantity'] != null) {
          if (data['productQuantity'] is String) {
            originalQuantity = int.tryParse(data['productQuantity']);
          } else if (data['productQuantity'] is int) {
            originalQuantity = data['productQuantity'];
          } else if (data['productQuantity'] is double) {
            originalQuantity = data['productQuantity'].toInt();
          }
        }
        
        setState(() {
          productNameController.text = data['productname'] ?? "";
          productNumberController.text = data['productnumber'] ?? "";
          quantityController.text = data['productQuantity']?.toString() ?? "";
          customerNameController.text = data['Customername'] ?? "";
          totalAmount = (data['Amount'] ?? 0).toDouble();
          pricePerUnit = originalQuantity != null && originalQuantity! > 0 
              ? totalAmount / originalQuantity! 
              : 0;
          
          // Handle Timestamp conversion properly
          if (data['Datetime'] != null) {
            if (data['Datetime'] is Timestamp) {
              selectedDate = (data['Datetime'] as Timestamp).toDate();
            } else {
              // Handle other date formats if needed
              selectedDate = DateTime.now();
            }
          }
        });
        
        // Load product information (in case price has changed)
        await _fetchProductInfo(originalProductNumber!);
      }
    } catch (e) {
      _showErrorMessage("Error loading transaction data: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchProductInfo(String productNumber) async {
    if (productNumber.isEmpty) return;
    
    try {
      // Query Firestore for products matching the product number
      final QuerySnapshot productSnapshot = await FirebaseFirestore.instance
          .collection("products")
          .where("productNumber", isEqualTo: productNumber)
          .limit(1)
          .get();

      // Check if any matching product was found
      if (productSnapshot.docs.isNotEmpty) {
        final doc = productSnapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        
        if (mounted) {
          setState(() {
            selectedProductId = doc.id;
            productNameController.text = data['name'] ?? "";
            
            // Store price per unit
            if (data['price'] != null) {
              if (data['price'] is double) {
                pricePerUnit = data['price'];
              } else if (data['price'] is int) {
                pricePerUnit = (data['price'] as int).toDouble();
              } else if (data['price'] is String) {
                pricePerUnit = double.tryParse(data['price']) ?? 0;
              }
            }
            
            // Recalculate total amount
            _calculateTotal();
          });
        }
      } else {
        // No product found with this number
        if (mounted) {
          setState(() {
            selectedProductId = null;
            pricePerUnit = 0;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching product data: $e");
    }
  }

  void _calculateTotal() {
    int quantity = int.tryParse(quantityController.text) ?? 0;
    setState(() {
      totalAmount = pricePerUnit * quantity;
    });
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<bool> _updateProductInventory({
    required String productNumber, 
    required int quantity, 
    bool isDelete = false,
  }) async {
    try {
      // Query Firestore for the product
      final QuerySnapshot productSnapshot = await FirebaseFirestore.instance
          .collection("products")
          .where("productNumber", isEqualTo: productNumber)
          .limit(1)
          .get();

      if (productSnapshot.docs.isEmpty) {
        _showErrorMessage("Product not found: $productNumber");
        return false;
      }
      
      final doc = productSnapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      
      // Get current quantity as int (handle different data types)
      int currentQuantity = 0;
      if (data['quantity'] != null) {
        if (data['quantity'] is int) {
          currentQuantity = data['quantity'];
        } else if (data['quantity'] is String) {
          currentQuantity = int.tryParse(data['quantity']) ?? 0;
        } else if (data['quantity'] is double) {
          currentQuantity = data['quantity'].toInt();
        }
      }
      
      // Calculate new quantity
      int newQuantity = currentQuantity;
      
      // If deleting a transaction, restore the inventory
      if (isDelete) {
        newQuantity += quantity;  // Add back the quantity
      } else {
        newQuantity -= quantity;  // Subtract the quantity (since it's a sale)
      }
      
      // Ensure quantity doesn't go negative
      if (newQuantity < 0) {
        _showErrorMessage("Not enough inventory available. Only $currentQuantity units in stock.");
        return false;
      }
      
      // Update the product quantity
      await FirebaseFirestore.instance
          .collection("products")
          .doc(doc.id)
          .update({
            'quantity': newQuantity,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
      return true;
    } catch (e) {
      _showErrorMessage("Error updating inventory: $e");
      return false;
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (user == null) {
      _showErrorMessage("You must be logged in to save transactions");
      return;
    }
    
    final String productNumber = productNumberController.text.trim();
    final int quantity = int.tryParse(quantityController.text.trim()) ?? 0;
    
    if (quantity <= 0) {
      _showErrorMessage("Quantity must be greater than zero");
      return;
    }
    
    setState(() => isLoading = true);
    
    try {
      // First, handle inventory updates
      
      // If editing a transaction, restore original inventory first
      if (widget.transactionId != null && originalProductNumber != null && originalQuantity != null) {
        // Check if product number has changed
        if (originalProductNumber != productNumber) {
          // Restore inventory for the original product
          await _updateProductInventory(
            productNumber: originalProductNumber!,
            quantity: originalQuantity!,
            isDelete: true,  // Restore inventory
          );
          
          // Deduct from the new product
          final success = await _updateProductInventory(
            productNumber: productNumber,
            quantity: quantity,
            isDelete: false,  // Deduct inventory
          );
          
          if (!success) {
            setState(() => isLoading = false);
            return;
          }
        } else {
          // Same product, just update the quantity difference
          final quantityDiff = quantity - originalQuantity!;
          
          if (quantityDiff != 0) {
            // If quantityDiff is positive, we need to deduct more
            // If negative, we're returning some inventory
            final success = await _updateProductInventory(
              productNumber: productNumber,
              quantity: quantityDiff > 0 ? quantityDiff : -quantityDiff,
              isDelete: quantityDiff < 0, // If diff is negative, we're restoring inventory
            );
            
            if (!success) {
              setState(() => isLoading = false);
              return;
            }
          }
        }
      } else {
        // New transaction, just deduct inventory
        final success = await _updateProductInventory(
          productNumber: productNumber,
          quantity: quantity,
          isDelete: false,  // Deduct inventory
        );
        
        if (!success) {
          setState(() => isLoading = false);
          return;
        }
      }
      
      // Now save the transaction data
      final transactionData = {
        'userId': user!.uid,
        'productname': productNameController.text.trim(),
        'productnumber': productNumber,
        'productQuantity': quantity,
        'Customername': customerNameController.text.trim(),
        'Amount': totalAmount,
        'pricePerUnit': pricePerUnit,
        'Datetime': selectedDate,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (widget.transactionId != null) {
        // Update existing transaction
        await FirebaseFirestore.instance
            .collection("transactions")
            .doc(widget.transactionId)
            .update(transactionData);
      } else {
        // Create new transaction
        transactionData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection("transactions")
            .add(transactionData);
      }
      
      // Navigate back after successful save
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transaction saved successfully!")),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showErrorMessage("Error saving transaction: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _deleteTransaction() async {
    setState(() => isLoading = true);
    
    try {
      // Restore inventory first
      if (originalProductNumber != null && originalQuantity != null) {
        await _updateProductInventory(
          productNumber: originalProductNumber!,
          quantity: originalQuantity!,
          isDelete: true, // Restore inventory
        );
      }
      
      // Delete the transaction
      await FirebaseFirestore.instance
          .collection("transactions")
          .doc(widget.transactionId)
          .delete();
          
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transaction deleted successfully")),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showErrorMessage("Error deleting transaction: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        pageinfo: widget.transactionId != null ? 'Edit Transaction' : 'Add Sales Transaction',
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: productNameController,
                        decoration: const InputDecoration(
                          labelText: "Product Name",
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true, // Make read-only as it should be fetched
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Product name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: productNumberController,
                        decoration: InputDecoration(
                          labelText: "Product Number",
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              _fetchProductInfo(productNumberController.text.trim());
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Product number is required';
                          }
                          if (selectedProductId == null) {
                            return 'Product not found';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Quantity Sold",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) => _calculateTotal(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Quantity is required';
                          }
                          final quantity = int.tryParse(value);
                          if (quantity == null || quantity <= 0) {
                            return 'Please enter a valid quantity';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: customerNameController,
                        decoration: const InputDecoration(
                          labelText: "Customer Name (Optional)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Price per Unit:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '₹${pricePerUnit.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Amount:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '₹${totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _saveTransaction,
                            icon: const Icon(Icons.save),
                            label: Text(widget.transactionId != null ? "Update" : "Save"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.cancel),
                            label: const Text("Cancel"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (widget.transactionId != null)
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Transaction'),
                                  content: const Text('Are you sure you want to delete this transaction? This will restore the product quantity to inventory.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context); // Close dialog
                                        _deleteTransaction();
                                      },
                                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text('Delete Transaction', style: TextStyle(color: Colors.red)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}