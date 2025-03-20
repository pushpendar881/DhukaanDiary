import 'package:flutter/material.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String shopname;
  final String pageinfo;

  const MyAppBar({super.key, required this.shopname, required this.pageinfo});

  @override
  Size get preferredSize => const Size.fromHeight(150); // Match toolbarHeight

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
            pageinfo,
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
