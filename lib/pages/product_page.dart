import 'package:dukaan_diary/components/my_app_bar.dart';
import 'package:dukaan_diary/components/my_product_tile.dart';
import 'package:flutter/material.dart';

class ProductPage extends StatelessWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(shopname: 'Shop Name', pageinfo: 'List of Products'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add_product_page'),
        child: Icon(Icons.add),
      ),
      body: Column(children: [MyProductTile()]),
    );
  }
}
