import 'package:demo_app/pages/shopping_page.dart';
import 'package:demo_app/pages/shopping_list.dart';
import 'package:demo_app/pages/Barcode_scanner.dart';
import 'package:demo_app/pages/camera_page.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final List<Widget> pages = [
    const Voicepage(),
    const CameraPage(),
    const BarcodeScanner(),
    const ShoppingPage(),
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
              Icons.list,
            ),
            label: "list",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera),
            label: "Camera",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: "Barcode Scanner",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shop),
            label: "Shopping",
          ),
        ],
      ),
    );
  }
}
