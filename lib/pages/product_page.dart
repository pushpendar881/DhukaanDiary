import 'package:dukaan_diary/components/my_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool isLoading = false;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(pageinfo: 'Product List'),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            '/add_product_page',
          );

          // Refresh UI if needed (StreamBuilder handles this automatically)
          if (result == true) {
            setState(() {});
          }
        },
        child: const Icon(Icons.add),
      ),
      body:
          user == null
              ? const Center(child: Text('Please login to view products'))
              : Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon:
                            _searchController.text.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      searchQuery = '';
                                    });
                                  },
                                )
                                : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                  // Product List
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('products')
                              .where('userId', isEqualTo: user!.uid)
                              .snapshots(),
                      builder: (context, snapshot) {
                        // Handle loading state
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        // Handle error state
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }

                        // Check if there's no data
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              'No products found. Add your first product!',
                              style: TextStyle(fontSize: 16),
                            ),
                          );
                        }

                        // Filter products based on search query
                        final filteredDocs =
                            snapshot.data!.docs.where((doc) {
                              final product =
                                  doc.data() as Map<String, dynamic>;
                              final productName =
                                  (product['name'] ?? '')
                                      .toString()
                                      .toLowerCase();
                              final productNumber =
                                  (product['productNumber'] ?? '')
                                      .toString()
                                      .toLowerCase();
                              final description =
                                  (product['description'] ?? '')
                                      .toString()
                                      .toLowerCase();

                              return productName.contains(searchQuery) ||
                                  productNumber.contains(searchQuery) ||
                                  description.contains(searchQuery);
                            }).toList();

                        // Show message when no results match search
                        if (filteredDocs.isEmpty && searchQuery.isNotEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.search_off,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No products matching "$searchQuery"',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        }

                        // Build the list when data is available
                        return ListView.builder(
                          itemCount: filteredDocs.length,
                          itemBuilder: (context, index) {
                            DocumentSnapshot doc = filteredDocs[index];
                            Map<String, dynamic> product =
                                doc.data() as Map<String, dynamic>;
                            String docId = doc.id;

                            // Calculate total price
                            double price = 0;
                            int quantity = 0;

                            try {
                              price =
                                  (product['price'] is int)
                                      ? (product['price'] as int).toDouble()
                                      : (product['price'] as double? ?? 0.0);

                              quantity = product['quantity'] as int? ?? 0;
                            } catch (e) {
                              debugPrint('Error parsing product values: $e');
                            }

                            double totalPrice = price * quantity;

                            return Dismissible(
                              key: Key(docId),
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text("Confirm"),
                                      content: const Text(
                                        "Are you sure you want to delete this product?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(false),
                                          child: const Text("CANCEL"),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(true),
                                          child: const Text("DELETE"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              onDismissed: (direction) => _deleteProduct(docId),
                              child: Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 8,
                                ),
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: const Icon(
                                    Icons.shopping_bag,
                                    color: Colors.blue,
                                    size: 30,
                                  ),
                                  title: Text(
                                    product['name'] ?? 'Unknown Product',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Product Number: ${product['productNumber'] ?? 'N/A'}",
                                      ),
                                      Text(
                                        "Price per Unit: ₹${price.toStringAsFixed(2)}",
                                      ),
                                      Text("Quantity: $quantity"),
                                      Text(
                                        "Total Price: ₹${totalPrice.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (product['description'] != null &&
                                          product['description']
                                              .toString()
                                              .isNotEmpty)
                                        Text(
                                          "Description: ${product['description']}",
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                    ],
                                  ),
                                  onTap: () => _editProduct(context, docId),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  Future<void> _deleteProduct(String docId) async {
    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting product: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _editProduct(BuildContext context, String productId) async {
    final result = await Navigator.pushNamed(
      context,
      '/add_product_page',
      arguments: {'productId': productId},
    );

    // Refresh UI if needed (StreamBuilder will handle this automatically)
    if (result == true) {
      setState(() {});
    }
  }
}
