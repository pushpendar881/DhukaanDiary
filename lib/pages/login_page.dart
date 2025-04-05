import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool isLoading = false;
  String verificationId = "";

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  // Input Validation Functions
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool isValidPhone(String phone) {
    return RegExp(r'^\d{10}$').hasMatch(phone);
  }

  // ✅ Email & Password Login
  Future<void> loginWithEmail() async {
    // Validate inputs
    if (emailController.text.trim().isEmpty || passwordController.text.isEmpty) {
      showError("Please fill in all fields");
      return;
    }

    if (!isValidEmail(emailController.text.trim())) {
      showError("Please enter a valid email address");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
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
      } else if (e.code == 'invalid-email') {
        errorMessage = "Invalid email format.";
      } else if (e.code == 'user-disabled') {
        errorMessage = "This account has been disabled.";
      }
      showError(errorMessage);
    } catch (e) {
      showError("Login failed: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ✅ Phone Number Login (OTP Verification)
  Future<void> loginWithPhone() async {
    // Validate phone number
    final phoneNumber = emailController.text.trim();
    if (phoneNumber.isEmpty || !isValidPhone(phoneNumber)) {
      showError("Please enter a valid 10-digit phone number");
      return;
    }

    setState(() {
      isLoading = true;
      isOtpSent = true;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: "+91$phoneNumber", // Make sure format matches your country
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (typically on Android)
          try {
            print("Auto-verification completed");
            final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
            if (userCredential.user != null) {
              Navigator.pushReplacementNamed(context, '/selected_page');
            }
          } catch (e) {
            print("Auto-verification failed: $e");
            showError("Auto-verification failed");
          } finally {
            setState(() {
              isLoading = false;
            });
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print("Verification failed: ${e.code} - ${e.message}");
          String errorMessage = "Phone verification failed";
          if (e.code == 'invalid-phone-number') {
            errorMessage = "The phone number format is incorrect";
          } else if (e.code == 'too-many-requests') {
            errorMessage = "Too many requests. Try again later";
          } else if (e.code == 'quota-exceeded') {
            errorMessage = "SMS quota exceeded. Try again later";
          }
          showError("$errorMessage: ${e.message}");
          setState(() {
            isOtpSent = false;
            isLoading = false;
          });
        },
        codeSent: (String verId, int? resendToken) {
          print("Code sent! VerificationId: $verId");
          setState(() {
            verificationId = verId;
            isLoading = false;
          });
          showSuccess("OTP Sent! Check your messages.");
        },
        codeAutoRetrievalTimeout: (String verId) {
          // This is called when the auto-retrieval times out
          print("Auto retrieval timeout. VerificationId: $verId");
          verificationId = verId;
        },
      );
    } catch (e) {
      print("General error sending OTP: $e");
      showError("Failed to send OTP: $e");
      setState(() {
        isOtpSent = false;
        isLoading = false;
      });
    }
  }

  // ✅ OTP Verification Function
  Future<void> verifyOTP() async {
    final otp = otpController.text.trim();
    
    // Validate OTP format
    if (otp.isEmpty || otp.length < 6) {
      showError("Please enter a valid 6-digit OTP");
      return;
    }
    
    // Ensure we have a verification ID
    if (verificationId.isEmpty) {
      showError("Verification failed. Please request OTP again.");
      setState(() {
        isOtpSent = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      print("Verifying OTP: $otp with verificationId: $verificationId");
      
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      
      // Try to sign in with the credential
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Check if we successfully got a user
      if (userCredential.user != null) {
        print("OTP verification successful");
        Navigator.pushReplacementNamed(context, '/selected_page');
      } else {
        print("User credential is null after verification");
        showError("Authentication failed. Please try again.");
      }
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Exception in verifyOTP: ${e.code} - ${e.message}");
      // Specific Firebase errors
      String errorMessage = "OTP verification failed";
      if (e.code == 'invalid-verification-code') {
        errorMessage = "The OTP you entered is incorrect";
      } else if (e.code == 'invalid-verification-id') {
        errorMessage = "Verification session expired. Please request OTP again";
        setState(() {
          isOtpSent = false;
        });
      }
      showError(errorMessage);
    } catch (e) {
      print("General exception in verifyOTP: $e");
      showError("Verification failed: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ✅ Resend OTP Function
  Future<void> resendOTP() async {
    setState(() {
      isOtpSent = false;
    });
    await loginWithPhone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
              Colors.blue.shade500,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with card effect
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'lib/images/DukaanDiary.png',
                        height: 140,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.store_rounded,
                            size: 100,
                            color: Colors.white,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Welcome text with animation
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Colors.white, Colors.white.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'You\'ve been missed!',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Login Type Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildToggleButton(
                            title: "Email",
                            isActive: isEmailLogin,
                            onTap: () {
                              setState(() {
                                isEmailLogin = true;
                                isOtpSent = false;
                              });
                            },
                          ),
                          _buildToggleButton(
                            title: "Phone",
                            isActive: !isEmailLogin,
                            onTap: () {
                              setState(() {
                                isEmailLogin = false;
                                isOtpSent = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Email/Phone Input Card
                    _buildInputCard(
                      child: TextField(
                        controller: emailController,
                        keyboardType: isEmailLogin ? TextInputType.emailAddress : TextInputType.phone,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: isEmailLogin ? "Enter your Email" : "Enter your Phone Number",
                          helperText: !isEmailLogin ? "10-digit number without country code" : null,
                          helperStyle: TextStyle(color: Colors.blue.shade200),
                          filled: false,
                          border: InputBorder.none,
                          prefixIcon: Icon(
                            isEmailLogin ? Icons.email_rounded : Icons.phone_android_rounded,
                            color: Colors.blue.shade800,
                          ),
                          prefixText: !isEmailLogin ? "+91 " : null,
                          prefixStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Field for Email Login
                    if (isEmailLogin) ...[
                      _buildInputCard(
                        child: TextField(
                          controller: passwordController,
                          obscureText: true,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: "Enter your password",
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              Icons.lock_rounded,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                      ),
                      
                      // Forgot Password Option
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            if (emailController.text.trim().isEmpty) {
                              showError("Please enter your email first");
                              return;
                            }
                            
                            if (!isValidEmail(emailController.text.trim())) {
                              showError("Please enter a valid email address");
                              return;
                            }
                            
                            FirebaseAuth.instance.sendPasswordResetEmail(
                              email: emailController.text.trim(),
                            ).then((_) {
                              showSuccess("Password reset email sent!");
                            }).catchError((error) {
                              showError("Failed to send reset email: $error");
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],

                    // OTP Field for Phone Login
                    if (!isEmailLogin && isOtpSent) ...[
                      _buildInputCard(
                        child: TextField(
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: const TextStyle(
                            fontSize: 18,
                            letterSpacing: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: "• • • • • •",
                            hintStyle: TextStyle(
                              letterSpacing: 8,
                              color: Colors.grey.shade400,
                            ),
                            border: InputBorder.none,
                            counterText: "",
                            prefixIcon: Icon(
                              Icons.security_rounded,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                      ),
                      
                      // Resend OTP Option
                      TextButton.icon(
                        onPressed: resendOTP,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text(
                          "Resend OTP",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],

                    const SizedBox(height: 30),

                    // Login / OTP Button
                    Container(
                      width: double.infinity,
                      height: 55,
                      margin: const EdgeInsets.symmetric(horizontal: 25),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.blue.shade200,
                          ],
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null // Disable button when loading
                            : isEmailLogin
                                ? loginWithEmail
                                : (isOtpSent ? verifyOTP : loginWithPhone),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.blue.shade800,
                                  strokeWidth: 3,
                                ),
                              )
                            : Text(
                                isEmailLogin
                                    ? "Sign In"
                                    : (isOtpSent ? "Verify OTP" : "Send OTP"),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                      ),
                    ),

                    // Sign Up Option
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Colors.white70),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => Signuppage()),
                            );
                          },
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build toggle buttons
  Widget _buildToggleButton({required String title, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.blue.shade800 : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Helper method to build input card
  Widget _buildInputCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}