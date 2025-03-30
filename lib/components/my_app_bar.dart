import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyAppBar extends StatefulWidget implements PreferredSizeWidget {

  final String pageinfo;

  const MyAppBar({super.key ,required this.pageinfo});

  @override
  State<MyAppBar> createState() => _MyAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(150); 
}

class _MyAppBarState extends State<MyAppBar> {
  String shopname="ShopName";
  User? user=FirebaseAuth.instance.currentUser;
  
  @override
  void initState(){
    super.initState();
    _loaduserData();
  }

  Future<void> _loaduserData()async{
    if(user!=null){
      try{
        DocumentSnapshot userdoc= await FirebaseFirestore.instance.collection("users").doc(user!.uid).get();
        if(userdoc.exists && mounted){
          setState(() {
            shopname=userdoc['shopName'] ?? "ShopName";
          });
        }
      }catch(e){
        print("Error loading shop name: $e");
      }
    }
  }

  
 // Match toolbarHeight
  

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 150, // Keep it consistent with preferredSize
      backgroundColor: Colors.blue[900],
      elevation: 10,
      shadowColor: Colors.black.withOpacity(0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Icon(Icons.shopping_cart, size: 35, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                shopname,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            widget.pageinfo,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white,
              decorationThickness: 2,
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }
}
