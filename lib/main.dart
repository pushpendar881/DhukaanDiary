<<<<<<< HEAD
import 'package:dhukaan/Pages/loginpage.dart';
import 'package:flutter/material.dart';
=======

import 'package:dukaandiary/pages/login_page.dart';
import 'package:flutter/material.dart';

>>>>>>> origin/main
// import 'package:dhukaan/Pages/SignupPage.dart';p

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
   return MaterialApp(
    debugShowCheckedModeBanner: false,
    home:LoginPage(),
   );
  }
}
