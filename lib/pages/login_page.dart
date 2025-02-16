import 'package:dukaandiary/pages/signup_page.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[300],
      appBar: AppBar(
        toolbarHeight: 90,
        backgroundColor: Colors.blue[900],
        title: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calculate_outlined,
                size: 35,
                color: Colors.white,
              ),
              SizedBox(width: 10),
              Text(
                "Dhukaan Diary",
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
     body: Center(
  child: SingleChildScrollView(
    child: Container(
      height: 455,
      width: MediaQuery.of(context).size.width * 0.9,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Account Name Field
          Row(
            children: [
              Icon(Icons.account_circle, size: 30, color: Colors.white),
              SizedBox(width: 10),
              Text(
                "Account Name:",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              hintText: "Enter your Email / Number",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          SizedBox(height: 20),

          // Password Field
          Row(
            children: [
              Icon(Icons.lock, size: 30, color: Colors.white),
              SizedBox(width: 10),
              Text(
                "Password:",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          TextField(
            obscureText: true,
            decoration: InputDecoration(
              hintText: "Enter your password",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          SizedBox(height: 30),

          // Submit Button
          Center(
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Form Submitted Successfully!")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: Text(
                "Submit",
                style: TextStyle(fontSize: 25, color: Colors.white),
              ),
            ),
          ),
          SizedBox(height: 20),

          // Forgot Password/Username
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Forgot Password / Username clicked!")),
              );
            },
            child: Text(
              "Forgot Password/Username?",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          SizedBox(height: 5),

          // Create Account
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Signuppage()),
              );
            },
            child: Text(
              "Create Account",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                decoration: TextDecoration.underline,
              ),
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
