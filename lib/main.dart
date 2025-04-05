import 'package:dukaan_diary/firebase_options.dart';
import 'package:dukaan_diary/models/selected_page.dart';
import 'package:dukaan_diary/pages/add_contact_page.dart';
import 'package:dukaan_diary/pages/add_employee.dart';
import 'package:dukaan_diary/pages/add_product_page.dart';
import 'package:dukaan_diary/pages/add_transaction_page.dart';
import 'package:dukaan_diary/pages/add_transaction_page_contact.dart';
import 'package:dukaan_diary/pages/history_page.dart';
import 'package:dukaan_diary/pages/login_page.dart';
import 'package:dukaan_diary/pages/view_transactions_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
      routes: {
        '/selected_page': (context) => SelectedPage(),
        '/login': (context) => LoginPage(),
        '/add_product_page': (context) => AddProductPage(),
        '/history_page': (context) => const HistoryPage(),
        '/add_transaction_page': (context) => const AddTransactionPage(),
        '/add_employee': (context) => const AddEmployeePage(),
        '/add_contact_page': (context) => const AddContactPage(),
        '/view_transactions_page': (context) {
          // Extract the arguments as a Map containing both contactId and phoneNumber
          final Map<String, String> args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
          return ViewTransactionsPage(
            contactId: args['contactId']!,
            contactName: args['contactName'] ?? '',
            phoneNumber: args['phoneNumber']!,
          );
        },
        '/add_transaction_page_contact': (context) {
          // Extract the arguments as a Map
          final Map<String, String> args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
          return AddTransactionPageContact(
            contactId: args['contactId']!,
            phoneNumber: args['phoneNumber']!,
          );
        },
      },
    );
  }
}