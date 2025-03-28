import 'package:flutter/material.dart';
import 'package:dukaan_diary/pages/signup_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool isEmailLogin = true;
  bool isOtpSent = false;
  String verificationId = "";

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ✅ Email & Password Login
  Future<void> loginWithEmail() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/selected_page');
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Login failed. Please try again.";
      if (e.code == 'user-not-found') {
        errorMessage = "No user found for that email.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Incorrect password. Please try again.";
      }
      showError(errorMessage);
    }
  }

  // ✅ Phone Number Login (OTP Verification)
  Future<void> loginWithPhone() async {
    setState(() {
      isOtpSent = true;
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: "+91${emailController.text.trim()}",
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        Navigator.pushReplacementNamed(context, '/selected_page');
      },
      verificationFailed: (FirebaseAuthException e) {
        showError("Phone verification failed: ${e.message}");
        setState(() {
          isOtpSent = false;
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          this.verificationId = verificationId;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("OTP Sent!")));
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  // ✅ OTP Verification Function
  Future<void> verifyOTP() async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      Navigator.pushReplacementNamed(context, '/selected_page');
    } catch (e) {
      showError("Invalid OTP. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade700,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'lib/images/DukaanDiary.png',
                  height: 140,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.image_not_supported,
                      size: 100,
                      color: Colors.white,
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome Back! You\'ve been missed!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 25),

                // ✅ Toggle Between Email & Phone Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isEmailLogin = true;
                          isOtpSent = false;
                        });
                      },
                      child: Text(
                        "Login with Email",
                        style: TextStyle(
                          color:
                              isEmailLogin
                                  ? Colors.white
                                  : Colors.grey.shade400,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isEmailLogin = false;
                          isOtpSent = false;
                        });
                      },
                      child: Text(
                        "Login with Number",
                        style: TextStyle(
                          color:
                              !isEmailLogin
                                  ? Colors.white
                                  : Colors.grey.shade400,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                // ✅ Email or Phone Input Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextField(
                    controller: emailController,
                    keyboardType:
                        isEmailLogin
                            ? TextInputType.emailAddress
                            : TextInputType.phone,
                    decoration: InputDecoration(
                      hintText:
                          isEmailLogin
                              ? "Enter your Email"
                              : "Enter your Phone Number",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ✅ Password Field for Email Login
                if (isEmailLogin) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: TextField(
                      controller: passwordController,
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
                  ),
                ],

                // ✅ OTP Field for Phone Login
                if (!isEmailLogin && isOtpSent) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Enter OTP",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // ✅ Login / OTP Button
                ElevatedButton(
                  onPressed:
                      isEmailLogin
                          ? loginWithEmail
                          : (isOtpSent ? verifyOTP : loginWithPhone),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.blue.shade500, // ✅ Lightened Button Color
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 15,
                    ),
                  ),
                  child: Text(
                    isEmailLogin
                        ? "Sign In"
                        : (isOtpSent ? "Verify OTP" : "Send OTP"),
                  ),
                ),

                // ✅ Sign Up Option
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Signuppage()),
                    );
                  },
                  child: const Text(
                    "Don't have an account? Sign Up",
                    style: TextStyle(color: Colors.white),
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
