import 'package:flutter/material.dart';
import 'package:dukaan_diary/components/my_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AddTransactionPage extends StatefulWidget {
  final String? transactionId;

  const AddTransactionPage({super.key, this.transactionId});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

// Class to represent a cart item
class CartItem {
  String productId;
  String productName;
  String productNumber;
  int quantity;
  double pricePerUnit;
  
  CartItem({
    required this.productId,
    required this.productName,
    required this.productNumber,
    required this.quantity,
    required this.pricePerUnit,
  });
  
  double get totalPrice => pricePerUnit * quantity;
  
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productNumber': productNumber,
      'quantity': quantity,
      'pricePerUnit': pricePerUnit,
      'totalPrice': totalPrice,
    };
  }
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController productNumberController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController customerNameController = TextEditingController(text: "Customer");
  
  // Transaction ID controller
  final TextEditingController transactionNumberController = TextEditingController();
  
  // List to store cart items
  List<CartItem> cartItems = [];
  
  String? currentProductName;
  double currentPricePerUnit = 0;
  String? currentProductId;
  
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  bool isNewTransaction = true;
  
  // Store information about original transaction for editing
  List<Map<String, dynamic>> originalItems = [];
  
  final User? user = FirebaseAuth.instance.currentUser;
  
  @override
  void initState() {
    super.initState();
    if (widget.transactionId != null) {
      isNewTransaction = false;
      _loadTransactionData();
    } else {
      // Generate a new transaction number for new transactions
      _generateTransactionNumber();
    }
  }

  @override
  void dispose() {
    productNumberController.dispose();
    quantityController.dispose();
    customerNameController.dispose();
    transactionNumberController.dispose();
    super.dispose();
  }

  // Generate a unique transaction number
  void _generateTransactionNumber() {
    // Format: TXN-YYYYMMDD-XXXX where XXXX is a random 4-digit number
    final dateStr = DateTime.now().toString().split(' ')[0].replaceAll('-', '');
    final randomDigits = Random().nextInt(9000) + 1000; // 1000-9999
    
    final txnNumber = "TXN-$dateStr-$randomDigits";
    transactionNumberController.text = txnNumber;
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
        
        setState(() {
          customerNameController.text = data['customerName'] ?? "Customer";
          transactionNumberController.text = data['transactionNumber'] ?? "";
          
          // Handle Timestamp conversion
          if (data['dateTime'] != null) {
            if (data['dateTime'] is Timestamp) {
              selectedDate = (data['dateTime'] as Timestamp).toDate();
            } else {
              selectedDate = DateTime.now();
            }
          }
          
          // Load items from the transaction
          if (data['items'] != null && data['items'] is List) {
            final items = List<Map<String, dynamic>>.from(data['items']);
            originalItems = items;
            
            // Convert to cart items
            cartItems = items.map((item) {
              return CartItem(
                productId: item['productId'] ?? '',
                productName: item['productName'] ?? '',
                productNumber: item['productNumber'] ?? '',
                quantity: (item['quantity'] is int) 
                    ? item['quantity'] 
                    : int.tryParse(item['quantity'].toString()) ?? 0,
                pricePerUnit: (item['pricePerUnit'] is double) 
                    ? item['pricePerUnit'] 
                    : double.tryParse(item['pricePerUnit'].toString()) ?? 0,
              );
            }).toList();
          }
        });
      }
    } catch (e) {
      _showErrorMessage("Error loading transaction data: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchProductInfo(String productNumber) async {
    if (productNumber.isEmpty) return;
    
    setState(() => isLoading = true);
    
    try {
      // Query Firestore for products matching the product number
      final QuerySnapshot productSnapshot = await FirebaseFirestore.instance
          .collection("products")
          .where("productNumber", isEqualTo: productNumber)
          .limit(1)
          .get();

      if (productSnapshot.docs.isNotEmpty) {
        final doc = productSnapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        
        setState(() {
          currentProductId = doc.id;
          currentProductName = data['name'] ?? "";
          
          // Store price per unit
          if (data['price'] != null) {
            if (data['price'] is double) {
              currentPricePerUnit = data['price'];
            } else if (data['price'] is int) {
              currentPricePerUnit = (data['price'] as int).toDouble();
            } else if (data['price'] is String) {
              currentPricePerUnit = double.tryParse(data['price']) ?? 0;
            }
          }
        });
      } else {
        // No product found with this number
        setState(() {
          currentProductId = null;
          currentProductName = null;
          currentPricePerUnit = 0;
        });
        _showErrorMessage("Product not found. Please check the product number.");
      }
    } catch (e) {
      _showErrorMessage("Error fetching product data: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _addToCart() {
    if (currentProductId == null || currentProductName == null) {
      _showErrorMessage("Please search for a valid product first");
      return;
    }
    
    final quantity = int.tryParse(quantityController.text.trim()) ?? 0;
    if (quantity <= 0) {
      _showErrorMessage("Quantity must be greater than zero");
      return;
    }
    
    // Check if this product is already in the cart
    final existingIndex = cartItems.indexWhere(
      (item) => item.productNumber == productNumberController.text.trim()
    );
    
    if (existingIndex >= 0) {
      // Update existing item
      setState(() {
        cartItems[existingIndex].quantity += quantity;
      });
    } else {
      // Add new item
      setState(() {
        cartItems.add(CartItem(
          productId: currentProductId!,
          productName: currentProductName!,
          productNumber: productNumberController.text.trim(),
          quantity: quantity,
          pricePerUnit: currentPricePerUnit,
        ));
      });
    }
    
    // Clear input fields for next item
    productNumberController.clear();
    quantityController.clear();
    setState(() {
      currentProductId = null;
      currentProductName = null;
      currentPricePerUnit = 0;
    });
  }
  
  void _removeFromCart(int index) {
    setState(() {
      cartItems.removeAt(index);
    });
  }

  double _calculateTotalAmount() {
    double total = 0;
    for (var item in cartItems) {
      total += item.totalPrice;
    }
    return total;
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
    bool isReturn = false,
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
      
      // Get current quantity as int
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
      int newQuantity = isReturn
          ? currentQuantity + quantity  // Return to inventory
          : currentQuantity - quantity;  // Remove from inventory
      
      // Ensure quantity doesn't go negative for sales
      if (!isReturn && newQuantity < 0) {
        _showErrorMessage("Not enough inventory for ${data['name']}. Only $currentQuantity units available.");
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

  // Check if transaction number already exists to avoid duplicates
  Future<bool> _isTransactionNumberUnique(String transactionNumber) async {
    if (widget.transactionId != null) {
      // If editing, the transaction number can remain the same
      return true;
    }
    
    try {
      final QuerySnapshot existingTransactions = await FirebaseFirestore.instance
          .collection("transactions")
          .where("transactionNumber", isEqualTo: transactionNumber)
          .limit(1)
          .get();
          
      return existingTransactions.docs.isEmpty;
    } catch (e) {
      _showErrorMessage("Error checking transaction number: $e");
      return false;
    }
  }

  Future<void> _saveTransaction() async {
    if (cartItems.isEmpty) {
      _showErrorMessage("Please add at least one product to the cart");
      return;
    }
    
    if (transactionNumberController.text.trim().isEmpty) {
      _showErrorMessage("Transaction number is required");
      return;
    }
    
    if (user == null) {
      _showErrorMessage("You must be logged in to save transactions");
      return;
    }
    
    setState(() => isLoading = true);
    
    try {
      // Verify transaction number uniqueness
      final String transactionNumber = transactionNumberController.text.trim();
      final bool isUnique = await _isTransactionNumberUnique(transactionNumber);
      
      if (!isUnique) {
        _showErrorMessage("Transaction number already exists. Please use a different one.");
        setState(() => isLoading = false);
        return;
      }
      
      // 1. Handle inventory updates
      
      // For editing: first restore original inventory if needed
      if (widget.transactionId != null && originalItems.isNotEmpty) {
        // Return original items to inventory
        for (var item in originalItems) {
          await _updateProductInventory(
            productNumber: item['productNumber'],
            quantity: item['quantity'] is int 
                ? item['quantity'] 
                : int.tryParse(item['quantity'].toString()) ?? 0,
            isReturn: true  // Add back to inventory
          );
        }
      }
      
      // Now deduct new cart items from inventory
      for (var item in cartItems) {
        final success = await _updateProductInventory(
          productNumber: item.productNumber,
          quantity: item.quantity,
          isReturn: false  // Remove from inventory
        );
        
        if (!success) {
          setState(() => isLoading = false);
          return; // Stop if any inventory update fails
        }
      }
      
      // 2. Save the transaction data
      final transactionData = {
        'userId': user!.uid,
        'transactionNumber': transactionNumber,
        'customerName': customerNameController.text.trim(),
        'totalAmount': _calculateTotalAmount(),
        'dateTime': selectedDate,
        'updatedAt': FieldValue.serverTimestamp(),
        'items': cartItems.map((item) => item.toMap()).toList(),
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
      // Restore all items to inventory
      for (var item in originalItems) {
        await _updateProductInventory(
          productNumber: item['productNumber'],
          quantity: item['quantity'] is int 
              ? item['quantity'] 
              : int.tryParse(item['quantity'].toString()) ?? 0,
          isReturn: true // Return to inventory
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

  Widget _buildProductSearchForm() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Add Products",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: productNumberController,
                    decoration: const InputDecoration(
                      labelText: "Product Number",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _fetchProductInfo(productNumberController.text.trim()),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("Search"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (currentProductName != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Product: $currentProductName",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text("Price: ₹${currentPricePerUnit.toStringAsFixed(2)}"),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Quantity",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _addToCart,
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text("Add"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartList() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Cart Items",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${cartItems.length} item(s)",
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const Divider(),
            if (cartItems.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("No items in cart"),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return ListTile(
                    title: Text(item.productName),
                    subtitle: Text("${item.quantity} × ₹${item.pricePerUnit.toStringAsFixed(2)}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "₹${item.totalPrice.toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeFromCart(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Amount:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "₹${_calculateTotalAmount().toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        pageinfo: widget.transactionId != null ? 'Edit Transaction' : 'Add Sales Transaction',
      ),
      backgroundColor: Colors.grey[100],
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
                      Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: transactionNumberController,
                                decoration: const InputDecoration(
                                  labelText: "Transaction Number",
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.receipt_long),
                                ),
                                readOnly: !isNewTransaction, // Only editable for new transactions
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Transaction number is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: customerNameController,
                                decoration: const InputDecoration(
                                  labelText: "Customer Name",
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ListTile(
                                title: Text(
                                  "Transaction Date: ${selectedDate.toLocal().toString().split(' ')[0]}",
                                ),
                                leading: const Icon(Icons.calendar_today),
                                onTap: () async {
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
                            ],
                          ),
                        ),
                      ),
                      _buildProductSearchForm(),
                      _buildCartList(),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _saveTransaction,
                              icon: const Icon(Icons.save),
                              label: Text(widget.transactionId != null ? "Update" : "Save"),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.cancel),
                              label: const Text("Cancel"),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.grey,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (widget.transactionId != null)
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Transaction'),
                                  content: const Text('Are you sure you want to delete this transaction? This will restore all products to inventory.'),
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