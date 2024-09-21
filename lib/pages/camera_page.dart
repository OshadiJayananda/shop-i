import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:demo_app/consts.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_gemini/flutter_gemini.dart' as gemini;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

extension StringComparison on String {
  bool equalsIgnoreCase(String other) {
    return this.toLowerCase() == other.toLowerCase();
  }
}

class _CameraPageState extends State<CameraPage> {
  final _database = FirebaseDatabase.instance.ref();
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  XFile? _imageFile;
  bool _isCapturing = false;
  bool isImageCaptured = false;

  void _retakePicture() {
    setState(() {
      _imageFile = null;
      isImageCaptured = false;
    });
  }

  Future<void> matchProducts(String scannedText, List<String> productNames,
      BuildContext context) async {
    final apiKey = GEMINI_API_KEY;

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 1,
        topK: 64,
        topP: 0.95,
        maxOutputTokens: 8192,
        responseMimeType: 'application/json',
      ),
      systemInstruction: Content.system(
          'Only match the product names from the provided list. Do not infer or generate new product names.'),
    );

    final chat = model.startChat(history: []);

    // Prepare the product list in a readable format
    final productDescriptions = productNames.map((name) {
      return 'Product Name: $name';
    }).join('\n');

    final inputMessage = 'Find matching products from the following list:\n'
        '$productDescriptions\n\nScanned Text: $scannedText';

    final content = Content.text(inputMessage);
    final response = await chat.sendMessage(content);

    print("Matching result: ${response.text}");

    final productNameFromGemini =
        response.text?.trim(); // Extracted from Gemini response

    // Ensure that productNameFromGemini is not null or empty before comparing
    final isProductInInventory = productNames.any((productName) {
      final normalizedProductNameFromGemini =
          productNameFromGemini?.trim() ?? '';

      return normalizedProductNameFromGemini.isNotEmpty &&
          productName.equalsIgnoreCase(normalizedProductNameFromGemini);
    });

    String resultMessage = isProductInInventory
        ? 'Product is available in the inventory!'
        : 'Product is NOT available in the inventory.';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Matching result'),
          content: SingleChildScrollView(
            child: Text('${response.text} \n\n $resultMessage'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _analyzeImage(BuildContext context) async {
    if (_imageFile != null) {
      try {
        final inputImage = InputImage.fromFilePath(_imageFile!.path);
        final textRecognizer = GoogleMlKit.vision.textRecognizer();
        final RecognizedText recognizedText =
            await textRecognizer.processImage(inputImage);

        final text = recognizedText.text.trim();

        // if (text.isEmpty) {
        //   throw Exception("No text recognized in the image.");
        // }

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Scanned Text'),
              content: SingleChildScrollView(
                child: Text(text),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );

        processScannedText('Dyson', context);

        // final productNames = await _fetchProductNamesFromFirebase();
        // final productBrands = await _fetchProductBrandsFromFirebase();

        // await matchProducts(text, productNames, context);

        textRecognizer.close();
      } catch (e) {
        print('Error analyzing image: $e');

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Error analyzing image: $e'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<void> processScannedText(
      String scannedText, BuildContext context) async {
    // Fetch product details from Firebase
    final productDetails = await _fetchProductDetailsFromFirebase();

    // Call the matching function
    matchScannedTextWithProducts(scannedText, productDetails, context);
  }

  Future<void> matchScannedTextWithProducts(String scannedText,
      List<Map<String, String>> productDetails, BuildContext context) async {
    // Normalize scanned text for comparison
    final normalizedScannedText = scannedText.trim().toLowerCase();

    // Check if the scanned text matches any product name or brand
    Map<String, String>? matchedProduct;

    for (var product in productDetails) {
      final productName = product['name']?.toLowerCase() ?? '';
      final productBrand = product['brand']?.toLowerCase() ?? '';

      if (productName.contains(normalizedScannedText) ||
          productBrand.contains(normalizedScannedText)) {
        matchedProduct = product;
        break;
      }
    }

    // Prepare the result message
    String resultMessage;
    if (matchedProduct != null) {
      resultMessage = 'Product found!\n\n'
          'Product ID: ${matchedProduct['id']}\n'
          'Product Name: ${matchedProduct['name']}\n'
          'Brand: ${matchedProduct['brand']}';
    } else {
      resultMessage = 'No matching product found in the inventory.';
    }

    // Show the result in a dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Matching Result'),
          content: SingleChildScrollView(
            child: Text(resultMessage),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<List<Map<String, String>>> _fetchProductDetailsFromFirebase() async {
    try {
      final snapshot = await _database.child('products').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map?;
        if (data != null) {
          final productDetails = data.values.map((e) {
            final product = e as Map?;
            return {
              'id': product?['Product ID']?.toString() ?? '',
              'name': product?['Product Name']?.toString() ?? '',
              'brand': product?['Brand']?.toString() ?? '',
            };
          }).toList();

          // Filter out any entries with missing or empty values for ID
          return productDetails
              .where((detail) => detail['id']?.isNotEmpty ?? false)
              .toList();
        }
      }
    } catch (e) {
      print("Error fetching product details from Firebase: $e");
    }
    return [];
  }

  Future<List<String>> _fetchProductNamesFromFirebase() async {
    try {
      final snapshot = await _database.child('products').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map?;
        if (data != null) {
          final productNames = data.values.map((e) {
            final product = e as Map?;
            return product?['Product Name']?.toString() ?? '';
          }).toList();

          return productNames.where((name) => name.isNotEmpty).toList();
        }
      }
    } catch (e) {
      print("Error fetching product names and brands from Firebase: $e");
    }
    return [];
  }

  Future<List<String>> _fetchProductBrandsFromFirebase() async {
    try {
      final snapshot = await _database.child('products').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map?;
        if (data != null) {
          final productNames = data.values.map((e) {
            final product = e as Map?;
            return product?['Brand']?.toString() ?? '';
          }).toList();

          return productNames.where((name) => name.isNotEmpty).toList();
        }
      }
    } catch (e) {
      print("Error fetching product names and brands from Firebase: $e");
    }
    return [];
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      _controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
      );
      _initializeControllerFuture = _controller.initialize();
      setState(() {});
    } on CameraException catch (e) {
      print('CameraException: ${e.code}\nError Message: ${e.description}');
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_isCapturing) return;
    setState(() {
      _isCapturing = true;
    });

    try {
      await _initializeControllerFuture;
      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final XFile file = await _controller.takePicture();
      file.saveTo(path);
      setState(() {
        _imageFile = file;
      });
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        _isCapturing = false;
        isImageCaptured = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
      ),
      body: Column(
        children: [
          if (_imageFile == null)
            Expanded(
              child: FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return Center(child: CameraPreview(_controller));
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                },
              ),
            )
          else
            Expanded(
                child: Center(
              child: Image.file(File(_imageFile!.path)),
            )),
          const SizedBox(height: 10),
          isImageCaptured
              ? ElevatedButton(
                  onPressed: () {
                    _analyzeImage(context);
                  },
                  child: const Text('Analyze Image'),
                )
              : ElevatedButton(
                  onPressed: _takePicture,
                  child: const Text('Capture Image'),
                ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _retakePicture,
            child: const Text('Retake Image'),
          ),
        ],
      ),
    );
  }
}
