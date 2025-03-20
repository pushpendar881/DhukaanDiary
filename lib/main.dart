import 'package:dukaan_diary/models/selected_page.dart';
import 'package:dukaan_diary/pages/add_product_page.dart';
import 'package:dukaan_diary/pages/history_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: SelectedPage(),
    routes: {
      '/add_product_page':(context)=> AddProductPage(),
      '/history_page':(context)=>const HistoryPage(),
    },);
  }
}
