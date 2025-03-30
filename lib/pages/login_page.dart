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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
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
     UserCredential userCredential= await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      // bool hasProfile = await checkUserProfile(userCredential.user!.uid);
    // Navigate to appropriate screen
    // if (hasProfile) {
    //   Navigator.pushReplacementNamed(context, '/selected_page');
    // } else {
    //   Navigator.pushReplacementNamed(context, '/profile');
    // }   
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
  // Future<bool> checkUserProfile(String uid) async{
  //   try{
  //     DocumentSnapshot userDoc= await FirebaseFirestore.instance
  //     .collection("users").doc(uid).get();
  //     if (!userDoc.exists) {
  //     return false;
  //   }
  //   return true;
  //   }catch(e){
  //     return false;
  //   }
  // }
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
                          color: isEmailLogin ? Colors.white : Colors.grey.shade400,
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
                          color: !isEmailLogin ? Colors.white : Colors.grey.shade400,
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
                    keyboardType: isEmailLogin ? TextInputType.emailAddress : TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: isEmailLogin ? "Enter your Email" : "Enter your Phone Number",
                      helperText: !isEmailLogin ? "10-digit number without country code" : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(isEmailLogin ? Icons.email : Icons.phone),
                      prefixText: !isEmailLogin ? "+91 " : null,
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
                        prefixIcon: const Icon(Icons.lock),
                      ),
                    ),
                  ),
                  
                  // ✅ Forgot Password Option
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Add forgot password functionality
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
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(color: Colors.white70),
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
                      maxLength: 6,
                      decoration: InputDecoration(
                        hintText: "Enter 6-digit OTP",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.security),
                        counterText: "",
                      ),
                    ),
                  ),
                  
                  // ✅ Resend OTP Option
                  TextButton(
                    onPressed: resendOTP,
                    child: const Text(
                      "Didn't receive code? Resend OTP",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // ✅ Login / OTP Button
                ElevatedButton(
                  onPressed: isLoading
                      ? null // Disable button when loading
                      : isEmailLogin
                          ? loginWithEmail
                          : (isOtpSent ? verifyOTP : loginWithPhone),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade500,
                    disabledBackgroundColor: Colors.blue.shade300,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 15,
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
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
