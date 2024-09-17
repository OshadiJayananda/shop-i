import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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

  void _retakePicture() {
    setState(() {
      _imageFile = null;
      isImageCaptured = false;
    });
  }

  void _analyzeImage() async {
    if (_imageFile != null) {
      try {
        // Load the image from file
        final inputImage = InputImage.fromFilePath(_imageFile!.path);

        // Create an instance of the text recognizer
        final textRecognizer = GoogleMlKit.vision.textRecognizer();

        // Process the image
        final RecognizedText recognizedText =
            await textRecognizer.processImage(inputImage);

        // Handle the recognized text
        final text = recognizedText.text;

        // Show the recognized text in an alert dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Recognized Text'),
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

        // Dispose of the recognizer
        textRecognizer.close();
      } catch (e) {
        // Handle exceptions
        print('Error analyzing image: $e');
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
            ),

          // Display captured image if available
          if (_imageFile != null)
            Expanded(
              child: Image.file(
                File(_imageFile!.path),
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          // Capture Image Button
          if (_imageFile == null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _takePicture,
                child: _isCapturing
                    ? const CircularProgressIndicator()
                    : const Text('Capture Image'),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton(
                onPressed: _retakePicture, // Implement _retakePicture logic
                child: const Text('Retake Image'),
              ),
            ),

          // Analyse Image Button, only shows after image is captured
          if (_imageFile != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _analyzeImage,
                child: const Text('Analyze Image'),
              ),
            ),
        ],
      ),
    );
  }
}
