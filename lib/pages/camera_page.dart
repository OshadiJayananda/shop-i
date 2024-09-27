// import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:demo_app/consts.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:path_provider/path_provider.dart';

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
        String matchedBrand = response.text!.trim();

        const $title = "Brand Matched";
        final $content = "Matching result: $matchedBrand";
        showCustomDialog(context, $title, $content);
      } else {
        const $title = "No Match Found";
        const $content =
            "Could not match any brand or product from the scanned text.";
        showCustomDialog(context, $title, $content);
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
        // showCustomDialog(context, $title, $content);
        extractBrand(text, context);
        textRecognizer.close();
      } catch (e) {
        print('Error analyzing image: $e');
        const $title = 'Error';
        final $content = 'Error analyzing image: $e';
        showCustomDialog(context, $title, $content);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
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
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
