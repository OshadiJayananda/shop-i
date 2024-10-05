import 'dart:io';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_gemini/flutter_gemini.dart' as gemini;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:demo_app/consts.dart';

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
  bool _isLoading = false;
  late FlutterTts flutterTts;

  // Firebase database references
  final DatabaseReference shoppingListRef =
      FirebaseDatabase.instance.ref().child('shopping_lists');
  final DatabaseReference promotionsRef =
      FirebaseDatabase.instance.ref().child('promotions');

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeTts();
  }

  void _initializeTts() {
    flutterTts = FlutterTts();
  }

  Future<void> _speakText(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

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

  // Function to fetch the shopping list from Firebase and check if item exists
  Future<String?> checkItemInShoppingList(String itemName) async {
    final snapshot = await shoppingListRef.get();
    if (snapshot.exists) {
      Map<dynamic, dynamic> shoppingList =
          snapshot.value as Map<dynamic, dynamic>;

      for (var entry in shoppingList.entries) {
        Map<dynamic, dynamic> itemFound =
            entry.value as Map<dynamic, dynamic>;
        if (itemFound['item'].toLowerCase() == itemName.toLowerCase()) {
          // Return formatted promotion string
          return "There is an ongoing ${itemFound['promotion']} promotion for ${itemFound['item']} from ${itemFound['brand']} until ${itemFound['duration']}.";
        }
      }
    }
    return null;
  }

  // Function to check if the item is in the promotions database
  Future<String?> checkPromotionsForItem(String itemName) async {
    final snapshot =
        await promotionsRef.get(); // Fetch the promotions from Firebase
    if (snapshot.exists) {
      Map<dynamic, dynamic> promotions =
          snapshot.value as Map<dynamic, dynamic>;

      for (var entry in promotions.entries) {
        Map<dynamic, dynamic> promotionData =
            entry.value as Map<dynamic, dynamic>;
        if (promotionData['item'].toLowerCase() == itemName.toLowerCase()) {
          // Return formatted promotion string
          return "There is an ongoing ${promotionData['promotion']} promotion for ${promotionData['item']} from ${promotionData['brand']} until ${promotionData['duration']}.";
        }
      }
    }
    return null; // No promotion found
  }

  Future<void> extractBrand(String scannedText, BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      const apiKey = GEMINI_API_KEY;

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
          'Give brand name or product name',
        ),
      );

      final chat = model.startChat(history: []);

      final inputMessage =
          'Find brand name or Product name from Scanned Text: $scannedText';

      final content = Content.text(inputMessage);
      final response = await chat.sendMessage(content);

      if (response.text!.isNotEmpty) {
        String productDetail = response.text!.trim().toLowerCase();
        final responseText = response.text!.trim();

        // Assuming the response text is in JSON format
        final Map<String, dynamic> jsonResponse = jsonDecode(responseText);

        String? productName;
        if (jsonResponse.containsKey('product_name')) {
          productName = jsonResponse['product_name'];
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Product Found'),
                content: Text('Product Name: $productName'),
                actions: <Widget>[
                  TextButton(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                  ),
                ],
              );
            },
          );
          print('Product Name: $productName');
        } else {
          print('Product name not found in response.');
        }

        if (productName != null) {
          // Now check if the extracted item is in the Firebase shopping list
          String? ItemInShoppingList =
              await checkItemInShoppingList(productName);

          bool isItemInShoppingList = false;

          if (ItemInShoppingList != null) {
            isItemInShoppingList = true;
          }

          // Check if there is any promotion for this item
          String? promotionDetails = await checkPromotionsForItem(productName);

          // Append message based on Firebase check result
          String shoppingListMessage = isItemInShoppingList
              ? "This item is on your shopping list."
              : "This item is not on your shopping list.";

          // If promotion is found, append the promotion details, otherwise show no promotion message
          String promotionMessage = promotionDetails != null
              ? promotionDetails
              : "There are no ongoing promotions for $productDetail.";

          const $title = "Brand Matched";
          final $content =
              "Matching result: $productDetail\n$shoppingListMessage\n$promotionMessage";

          showCustomDialog(context, $title, $content);

          // Speak the matched text along with shopping list and promotion status
          _speakText(
              "Matching result: $productDetail. $shoppingListMessage. $promotionMessage");
        } else {
          // Handle case where no product name is found
          const $title = "No Match Found";
          const $content =
              "Could not match any product name. Please try again.";
          showCustomDialog(context, $title, $content);
        }
      } else {
        const $title = "Error";
        const $content = "Failed to analyze the image. Please try again.";
        showCustomDialog(context, $title, $content);
      }
    } catch (e) {
      const $title = "Error";
      const $content = "An error occurred while processing: $e";
      showCustomDialog(context, $title, $content);
    } finally {
      setState(() {
        _isLoading = false; // Stop loading indicator
      });
    }
  }

  Future<void> _analyzeImage(BuildContext context) async {
    if (_imageFile == null) return;

    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      final inputImage = InputImage.fromFilePath(_imageFile!.path);
      final textDetector = GoogleMlKit.vision.textDetector();
      final RecognizedText recognizedText =
          await textDetector.processImage(inputImage);
      final String scannedText = recognizedText.text;

      // Check if there's any recognized text
      if (scannedText.isNotEmpty) {
        // Now extract the brand name
        await extractBrand(scannedText, context);
      } else {
        showCustomDialog(context, 'No Text Found',
            'No text could be recognized from the image.');
      }
    } catch (e) {
      showCustomDialog(context, 'Error', 'Failed to analyze the image: $e');
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  Future<void> _takePicture() async {
    if (_isCapturing) return;
    _isCapturing = true;

    try {
      await _initializeControllerFuture;
      final XFile picture = await _controller.takePicture();

      setState(() {
        _imageFile = picture; // Save the image file
        isImageCaptured = true; // Image has been captured
      });
    } catch (e) {
      print('Error capturing picture: $e');
    } finally {
      _isCapturing = false;
    }
  }

  Future<void> _initializeCamera() async {
    // Obtain a list of the available cameras on the device.
    final cameras = await availableCameras();
    // Get a specific camera from the list of available cameras.
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
    );

    // Initialize the controller.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Page'),
      ),
      body: Column(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                // If the Future is complete, display the preview.
                return SizedBox(
                  height: 300,
                  child: CameraPreview(_controller),
                );
              } else {
                // Otherwise, display a loading indicator.
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          const SizedBox(height: 20),
          if (isImageCaptured && _imageFile != null)
            Expanded(
              child: Column(
                children: [
                  Image.file(
                    File(_imageFile!.path),
                    fit: BoxFit.cover,
                    height: 300,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _retakePicture,
                        child: const Text('Retake Picture'),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () {
                          _analyzeImage(context);
                        },
                        child: const Text('Analyze Image'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        tooltip: 'Take Picture',
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  void showCustomDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
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
