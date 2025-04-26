import 'package:dukaan_diary/components/my_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProductPage extends StatefulWidget {
  // Optional parameter to receive product ID for editing
  final String? productId;

  const AddProductPage({super.key, this.productId});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController productNumberController = TextEditingController();
  final TextEditingController productPriceController = TextEditingController();
  final TextEditingController productQuantityController =
      TextEditingController();
  final TextEditingController productDescriptionController =
      TextEditingController();

  double totalPrice = 0;
  bool isLoading = false;
  bool isProductNumberUnique = true;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _loadProductData();
    }
  }

  @override
  void dispose() {
    // Clean up controllers to avoid memory leaks
    productNameController.dispose();
    productNumberController.dispose();
    productPriceController.dispose();
    productQuantityController.dispose();
    productDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadProductData() async {
    if (user == null || widget.productId == null) return;

    setState(() => isLoading = true);

    try {
      final DocumentSnapshot productSnapshot =
          await FirebaseFirestore.instance
              .collection("products")
              .doc(widget.productId)
              .get();

      if (productSnapshot.exists) {
        final data = productSnapshot.data() as Map<String, dynamic>;

        // Handle different data types from Firestore
        double price = 0;
        int quantity = 0;

        try {
          price =
              (data['price'] is int)
                  ? (data['price'] as int).toDouble()
                  : (data['price'] is String)
                  ? double.tryParse(data['price'] as String) ?? 0.0
                  : (data['price'] as double? ?? 0.0);

          quantity =
              (data['quantity'] is String)
                  ? int.tryParse(data['quantity'] as String) ?? 0
                  : (data['quantity'] as int? ?? 0);
        } catch (e) {
          debugPrint('Error parsing product values: $e');
        }

        setState(() {
          productNameController.text = data['name'] ?? "";
          productNumberController.text = data['productNumber'] ?? "";
          productPriceController.text = price.toString();
          productQuantityController.text = quantity.toString();
          productDescriptionController.text = data['description'] ?? "";

          // Recalculate total price
          _calculateTotal();
        });
      }
    } catch (e) {
      _showErrorMessage("Error loading product data: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _calculateTotal() {
    double price = double.tryParse(productPriceController.text) ?? 0;
    int quantity = int.tryParse(productQuantityController.text) ?? 0;
    setState(() {
      totalPrice = price * quantity;
    });
  }

  Future<bool> _checkProductNumberUnique(String productNumber) async {
    if (productNumber.isEmpty) return false;

    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection("products")
              .where("productNumber", isEqualTo: productNumber)
              .get();

      // If editing an existing product, we need to exclude the current product ID
      if (widget.productId != null) {
        // Filter out the current product from results
        final filteredDocs =
            snapshot.docs.where((doc) => doc.id != widget.productId).toList();

        return filteredDocs
            .isEmpty; // Number is unique if no other products have it
      }

      // For new products, number is unique if no documents found
      return snapshot.docs.isEmpty;
    } catch (e) {
      debugPrint('Error checking product number uniqueness: $e');
      return false;
    }
  }

  Future<void> _validateProductNumber(String number) async {
    if (number.isEmpty) {
      setState(() => isProductNumberUnique = true);
      return;
    }

    final isUnique = await _checkProductNumberUnique(number);

    if (mounted) {
      setState(() => isProductNumberUnique = isUnique);
    }
  }

  Future<void> _saveProduct() async {
    if (user == null) {
      _showErrorMessage("User not authenticated");
      return;
    }

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check product number uniqueness again before saving
    final productNumber = productNumberController.text.trim();
    final isUnique = await _checkProductNumberUnique(productNumber);

    if (!isUnique) {
      _showErrorMessage("Product number must be unique");
      return;
    }

    // Parse values
    String name = productNameController.text.trim();
    double price = double.tryParse(productPriceController.text.trim()) ?? 0.0;
    int quantity = int.tryParse(productQuantityController.text.trim()) ?? 0;
    String description = productDescriptionController.text.trim();

    setState(() => isLoading = true);

    try {
      // Create product data map
      final productData = {
        'userId': user!.uid,
        'name': name,
        'productNumber': productNumber,
        'price': price,
        'quantity': quantity,
        'description': description,
        'totalPrice': totalPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // If creating new product
      if (widget.productId == null) {
        productData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection("products")
            .add(productData);
      }
      // If updating existing product
      else {
        await FirebaseFirestore.instance
            .collection("products")
            .doc(widget.productId)
            .update(productData);
      }

      // Show success and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product saved successfully!")),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage("Error saving product: $e");
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        pageinfo: widget.productId == null ? 'Add Product' : 'Edit Product',
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextFormField(
                          controller: productNameController,
                          label: "Product Name",
                          hint: "Enter product name",
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter product name';
                            }
                            return null;
                          },
                        ),
                        _buildTextFormField(
                          controller: productNumberController,
                          label: "Product Number",
                          hint: "Enter product number/code",
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter product number';
                            }
                            if (!isProductNumberUnique) {
                              return 'This product number is already in use';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            _validateProductNumber(value);
                          },
                        ),
                        _buildTextFormField(
                          controller: productPriceController,
                          label: "Price per Unit",
                          hint: "Enter price per unit",
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (val) => _calculateTotal(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter price';
                            }
                            final price = double.tryParse(value);
                            if (price == null || price <= 0) {
                              return 'Please enter a valid price';
                            }
                            return null;
                          },
                        ),
                        _buildTextFormField(
                          controller: productQuantityController,
                          label: "Quantity",
                          hint: "Enter quantity",
                          keyboardType: TextInputType.number,
                          onChanged: (val) => _calculateTotal(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter quantity';
                            }
                            final quantity = int.tryParse(value);
                            if (quantity == null || quantity < 0) {
                              return 'Please enter a valid quantity';
                            }
                            return null;
                          },
                        ),
                        _buildTextFormField(
                          controller: productDescriptionController,
                          label: "Product Description",
                          hint: "Enter product description",
                          maxLines: 3,
                          validator: null, // Optional field
                        ),
                        const SizedBox(height: 20),
                        _buildTotalPriceCard(),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
        ),
        keyboardType: keyboardType,
        onChanged: onChanged,
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }

  Widget _buildTotalPriceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Price:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            '₹${totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: _saveProduct,
          icon: const Icon(Icons.save),
          label: const Text("Save"),
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
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
