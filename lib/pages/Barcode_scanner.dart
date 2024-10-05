import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:firebase_database/firebase_database.dart';

class BarcodeScanner extends StatefulWidget {
  const BarcodeScanner({super.key});

  @override
  _BarcodeScannerState createState() => _BarcodeScannerState();
}

class _BarcodeScannerState extends State<BarcodeScanner> {
  MobileScannerController cameraController = MobileScannerController();
  FlutterTts flutterTts = FlutterTts();
  final DatabaseReference _databaseReference =
  FirebaseDatabase.instance.ref().child('products');

  bool isScanning = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _readOutLoud(String text) async {
    await flutterTts.speak(text);
  }

  Future<void> _fetchProductDetails(String barcode) async {
    final DataSnapshot snapshot = await _databaseReference.child(barcode).get();
    if (snapshot.exists) {
      final productDetails = snapshot.value as Map<dynamic, dynamic>;
      String productName = productDetails['name'] ?? 'Unknown product';
      String productPrice = productDetails['price'] ?? 'Unknown price';
      String expirationDate =
          productDetails['expirationDate'] ?? 'No expiration date';

      String message =
          "Product name: $productName. Price: $productPrice. Expiration date: $expirationDate.";

      _readOutLoud(message);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Product Details"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
      _readOutLoud("Product not found");
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
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) {
          if (!isScanning) {
            isScanning = true;
            final barcode = capture.barcodes.first.rawValue;
            if (barcode != null) {
              _fetchProductDetails(barcode).then((_) {
                setState(() {
                  isScanning = false;
                });
              });
            }
          }
        },
      ),
    );
  }
}
