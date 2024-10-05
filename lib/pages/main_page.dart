import 'package:demo_app/pages/home_page.dart';
import 'package:demo_app/pages/profile_page.dart';
import 'package:demo_app/pages/settings_page.dart';
import 'package:demo_app/pages/shopping_page.dart';
import 'package:demo_app/pages/shopping_list.dart';
import 'package:demo_app/pages/Barcode_scanner.dart'; // Import the BarcodeScanner page
import 'package:demo_app/pages/camera_page.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final List<Widget> pages = [
    const HomePage(),
    const Voicepage(),
    const ShoppingPage(),
    const BarcodeScanner(),
    // Ensure BarcodeScanner is listed here
    const CameraPage(),
    const ProfilePage(),
    const SettingsPage(),
  ];

  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentPage],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentPage,
        onTap: (value) {
          setState(() {
            currentPage = value;
          });
        },
        selectedItemColor: Colors.black, // For selected item color
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
            ),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shop),
            label: "Shopping",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: "Barcode Scanner",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera),
            label: "Camera",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.settings,
            ),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
