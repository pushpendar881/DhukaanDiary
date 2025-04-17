import 'package:dukaan_diary/models/selected_page.dart';
import 'package:dukaan_diary/pages/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          //user is logged im
          if (snapshot.hasData) {
            return SelectedPage();
          }
          //user is not logged in
          else {
            return LoginPage();
          }
        },
      ),
    );
  }
}
