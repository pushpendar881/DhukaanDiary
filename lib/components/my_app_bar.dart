import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String pageinfo;

  const MyAppBar({super.key, required this.pageinfo});

  @override
  State<MyAppBar> createState() => _MyAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(160);
}

class _MyAppBarState extends State<MyAppBar> {
  String shopname = "ShopName";
  String? shopIcon;
  User? user = FirebaseAuth.instance.currentUser;
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      try {
        setState(() {
          isLoading = true;
        });
        
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user!.uid)
            .get();
            
        if (userDoc.exists && mounted) {
          setState(() {
            shopname = userDoc['shopName'] ?? "ShopName";
            shopIcon = userDoc['shopIcon']; // Optional field for custom icon
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } catch (e) {
        print("Error loading shop name: $e");
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 160,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[900]!,
              Colors.blue[700]!,
              Colors.blue[800]!,
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Shop Logo and Name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 25,
                        height: 25,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      )
                    : Icon(
                        shopIcon != null ? getIconData(shopIcon!) : Icons.store_rounded,
                        size: 30,
                        color: Colors.blue[900],
                      ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  shopname,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        blurRadius: 5.0,
                        color: Color.fromARGB(70, 0, 0, 0),
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 25),
          
          // Page Title Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              widget.pageinfo,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }
  
  // Helper method to convert string to IconData (if you implement custom icons)
  IconData getIconData(String iconName) {
    // You can expand this map with more icons as needed
    final Map<String, IconData> iconMap = {
      'store': Icons.store_rounded,
      'shopping': Icons.shopping_cart_rounded,
      'shop': Icons.storefront_rounded,
      'business': Icons.business_center_rounded,
      'retail': Icons.local_mall_rounded,
      'grocery': Icons.local_grocery_store_rounded,
      'restaurant': Icons.restaurant_rounded,
      'cafe': Icons.local_cafe_rounded,
      'fashion': Icons.checkroom_rounded,
    };
    
    return iconMap[iconName.toLowerCase()] ?? Icons.store_rounded;
  }
}