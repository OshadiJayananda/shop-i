import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'camera_page.dart'; // Import the camera page

class Voicepage extends StatefulWidget {
  const Voicepage({super.key});

  @override
  State<Voicepage> createState() => _VoicepageState();
}

class _VoicepageState extends State<Voicepage> {
  final SpeechToText _speechToText = SpeechToText();
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  bool _speechEnabled = false;
  String _wordsSpoken = "";
  double _confidenceLevel = 0;

  @override
  void initState() {
    super.initState();
    initSpeech();
  }

  void initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {
      _confidenceLevel = 0;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(result) {
    setState(() {
      _wordsSpoken = "${result.recognizedWords}";
      _confidenceLevel = result.confidence;
    });

    // Check if the user said 'Go to camera' and navigate
    if (_wordsSpoken.toLowerCase() == "go to camera") {
      _navigateToCameraPage();
    }
    // Check if the user wants to delete an item by saying 'Delete $itemName'
    else if (_wordsSpoken.toLowerCase().startsWith('delete ')) {
      String itemToDelete = _wordsSpoken.substring(7).trim(); // Extract item name after 'Delete'
      _deleteFromRealtimeDatabase(itemToDelete);
    }
    // Otherwise, add the spoken item to the shopping list
    else if (_wordsSpoken.isNotEmpty) {
      _sendToRealtimeDatabase(_wordsSpoken);
    }
  }

  // Function to send the recognized speech to Firebase Realtime Database
  Future<void> _sendToRealtimeDatabase(String item) async {
    try {
      // Generating a new key for each item in the shopping list
      String key = _databaseRef.child('shopping_lists').push().key!;

      // Sending data to 'shopping_lists' node in Firebase Realtime Database
      await _databaseRef.child('shopping_lists/$key').set({
        'item': item,
        'addedAt': DateTime.now().toString(), // Use current time as string
      });

      print("Item added to Realtime Database: $item");
    } catch (e) {
      print("Failed to add item: $e");
    }
  }

  // Function to delete all instances of the spoken item from the database
  Future<void> _deleteFromRealtimeDatabase(String item) async {
    try {
      DatabaseReference shoppingListsRef = _databaseRef.child('shopping_lists');

      // Query the database to find matching items
      DataSnapshot snapshot = await shoppingListsRef.once().then((event) => event.snapshot);
      Map<dynamic, dynamic>? items = snapshot.value as Map<dynamic, dynamic>?;

      if (items != null) {
        // Loop through all items and delete matching ones
        items.forEach((key, value) async {
          if (value['item'].toString().toLowerCase() == item.toLowerCase()) {
            await shoppingListsRef.child(key).remove();
            print("Deleted item: $item");
          }
        });
      }
    } catch (e) {
      print("Failed to delete item: $e");
    }
  }

  // Function to navigate to the camera page
  void _navigateToCameraPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraPage()), // Navigate to camera_page.dart
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text(
          'Shopping list',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              child: Text(
                _speechToText.isListening
                    ? "Listening..."
                    : _speechEnabled
                    ? "Tap the microphone to start listening..."
                    : "Speech not available",
                style: TextStyle(fontSize: 20.0),
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                child: Text(
                  _wordsSpoken,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
            if (_speechToText.isNotListening && _confidenceLevel > 0)
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 100,
                ),
                child: Text(
                  "Confidence: ${(_confidenceLevel * 100).toStringAsFixed(1)}%",
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w200,
                  ),
                ),
              )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _speechToText.isListening ? _stopListening : _startListening,
        tooltip: 'Listen',
        child: Icon(
          _speechToText.isNotListening ? Icons.mic_off : Icons.mic,
          color: Colors.white,
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}