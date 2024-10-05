import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // Import Firebase Realtime Database
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:demo_app/consts.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  XFile? _imageFile;
  bool _isCapturing = false;
  bool isImageCaptured = false;
  bool _isLoading = false;
  late FlutterTts flutterTts; // TTS instance

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

  Future<void> showCustomDialog(
      BuildContext context, String title, String content) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              child: const Text("OK"),
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
  Future<bool> checkItemInShoppingList(String itemName) async {
    final snapshot = await shoppingListRef.get();
    if (snapshot.exists) {
      Map<dynamic, dynamic> shoppingList = snapshot.value as Map<dynamic, dynamic>;

      // Check if the item name is in the shopping list
      bool itemFound = shoppingList.containsValue(itemName.toLowerCase());
      return itemFound;
    }
    return false;
  }

  // Function to check if the item is in the promotions database
  Future<String?> checkPromotionsForItem(String itemName) async {
    final snapshot = await promotionsRef.get(); // Fetch the promotions from Firebase
    if (snapshot.exists) {
      Map<dynamic, dynamic> promotions = snapshot.value as Map<dynamic, dynamic>;

      for (var entry in promotions.entries) {
        Map<dynamic, dynamic> promotionData = entry.value as Map<dynamic, dynamic>;
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

      if (response != null && response.text!.isNotEmpty) {
        String matchedBrand = response.text!.trim().toLowerCase();

        // Now check if the extracted item is in the Firebase shopping list
        bool isItemInShoppingList = await checkItemInShoppingList(matchedBrand);

        // Check if there is any promotion for this item
        String? promotionDetails = await checkPromotionsForItem(matchedBrand);

        // Append message based on Firebase check result
        String shoppingListMessage = isItemInShoppingList
            ? "This item is on your shopping list."
            : "This item is not on your shopping list.";

        // If promotion is found, append the promotion details, otherwise show no promotion message
        String promotionMessage = promotionDetails != null
            ? promotionDetails
            : "There are no ongoing promotions for $matchedBrand.";

        const $title = "Brand Matched";
        final $content =
            "Matching result: $matchedBrand\n$shoppingListMessage\n$promotionMessage";

        showCustomDialog(context, $title, $content);

        // Speak the matched text along with shopping list and promotion status
        _speakText(
            "Matching result: $matchedBrand. $shoppingListMessage. $promotionMessage");
      } else {
        const $title = "No Match Found";
        const $content =
            "Could not match any brand or product from the scanned text.";
        showCustomDialog(context, $title, $content);

        // Speak the "no match" result
        _speakText("Could not match any brand or product.");
      }
    } catch (error) {
      print('Error occurred: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _analyzeImage(BuildContext context) async {
    if (_imageFile != null) {
      try {
        final inputImage = InputImage.fromFilePath(_imageFile!.path);
        final textRecognizer = GoogleMlKit.vision.textRecognizer();
        final RecognizedText recognizedText =
            await textRecognizer.processImage(inputImage);

        final text = recognizedText.text.trim();

        if (text.isEmpty) {
          throw Exception("No text recognized in the image.");
        }
        const $title = 'Scanned Text';
        final $content = text;
        extractBrand(text, context);
        textRecognizer.close();
      } catch (e) {
        print('Error analyzing image: $e');
        const $title = 'Error';
        final $content = 'Error analyzing image: $e';
        showCustomDialog(context, $title, $content);
        _speakText('Error analyzing image');
      }
    }
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
    flutterTts.stop(); // Stop any speech on dispose
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
      body: Stack(
        children: [
          Column(
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
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Image.file(File(_imageFile!.path)),
                  ),
                ),
              const SizedBox(height: 10),
              isImageCaptured
                  ? ElevatedButton(
                      onPressed: () => _analyzeImage(context),
                      child: const Text('Analyze Image'))
                  : ElevatedButton(
                      onPressed: _takePicture,
                      child: _isCapturing
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text('Capture Image'),
                    ),
              if (isImageCaptured)
                ElevatedButton(
                  onPressed: _retakePicture,
                  child: const Text('Retake'),
                ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}