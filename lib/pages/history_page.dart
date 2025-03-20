import 'package:dukaan_diary/components/my_app_bar.dart';
import 'package:dukaan_diary/components/my_list_tile.dart';
import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar(shopname: 'Shop name', pageinfo: 'All Transactions'),
      body: ListView(
        children: [
          for (int i = 1; i < 15; i++) MyListTile(index: i),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
