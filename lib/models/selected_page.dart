import 'package:dukaan_diary/pages/add_employee.dart';
import 'package:dukaan_diary/pages/contact_page.dart';
import 'package:dukaan_diary/pages/home_page.dart';
import 'package:dukaan_diary/pages/product_page.dart';
import 'package:dukaan_diary/pages/profile_page.dart';
import 'package:dukaan_diary/pages/staff_page.dart';
import 'package:flutter/material.dart';

class SelectedPage extends StatefulWidget {
  const SelectedPage({super.key});

  @override
  State<SelectedPage> createState() => _SelectedPageState();
}

class _SelectedPageState extends State<SelectedPage> {
  int _selectedIndex = 2; // Set home as the default selected index

  final List<Widget> _pages = [
    const ContactPage(),
    const StaffPage(),
    const HomePage(),
    const ProductPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          child: BottomNavigationBar(
            elevation: 8,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.blue[900],
            unselectedItemColor: Colors.grey,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedFontSize: 12,
            unselectedFontSize: 10,
            iconSize: 26,
            items: [
              _buildNavItem(Icons.contacts, "Contacts"),
              _buildNavItem(Icons.emoji_people_outlined, "Staff"),
              _buildNavItem(Icons.home_rounded, "Home"),
              _buildNavItem(Icons.inventory_2_rounded, "Product"),
              _buildNavItem(Icons.person, "Profile"),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Icon(icon),
      ),
      activeIcon: Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Icon(
          icon,
          size: 28,
        ),
      ),
      label: label,
    );
  }
}