import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:firebase_database/firebase_database.dart';

class BarcodeScanner extends StatefulWidget {
  const BarcodeScanner({Key? key}) : super(key: key);

  @override
  _BarcodeScannerState createState() => _BarcodeScannerState();
}

class _BarcodeScannerState extends State<BarcodeScanner> {
  MobileScannerController cameraController = MobileScannerController();
  FlutterTts flutterTts = FlutterTts();
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.ref().child('products'); // Firebase node

  TextEditingController _searchController = TextEditingController();
  bool isScanning = false;

  @override
  void dispose() {
    cameraController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _readOutLoud(String text) async {
    await flutterTts.speak(text);
  }

  Future<void> _fetchProductDetails(String barcode) async {
    final DataSnapshot snapshot = await _databaseReference.child(barcode).get();
    if (snapshot.exists) {
      final productDetails = snapshot.value as Map<dynamic, dynamic>;
      String brand = productDetails['Brand'] ?? 'Unknown brand';
      String productName =
          productDetails['Product Name'] ?? 'Unknown product name';
      String price = productDetails['Price'].toString() ?? 'Unknown price';

      String message =
          "Brand: $brand. Product Name: $productName. Price: $price.";

      _readOutLoud(message);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Product Details"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        ),
      );
    } else {
      _readOutLoud("Product not found");
    }
  }

  void _searchProduct() {
    String searchQuery = _searchController.text.trim();
    if (searchQuery.isNotEmpty) {
      _fetchProductDetails(searchQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () {
              cameraController.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () {
              cameraController.switchCamera();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by barcode',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchProduct,
                ),
              ),
              onSubmitted: (value) {
                _searchProduct();
              },
            ),
          ),
          Expanded(
            child: MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                if (!isScanning) {
                  isScanning = true;
                  final barcode = capture.barcodes.first.rawValue;
                  if (barcode != null) {
                    setState(() {
                      _searchController.text =
                          barcode; // Set scanned barcode in search bar
                    });
                    _fetchProductDetails(barcode).then((_) {
                      setState(() {
                        isScanning = false;
                      });
                    });
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
