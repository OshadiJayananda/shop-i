// import 'package:flutter/material.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;

// class SpeechHandler {
//   late stt.SpeechToText _speech;
//   bool _isListening = false;
//   String _lastCommand = '';
//   Function(String) onCommandRecognized;

//   SpeechHandler(this.onCommandRecognized);

//   // Initialize speech recognition
//   Future<void> initSpeech() async {
//     _speech = stt.SpeechToText();
//     bool available = await _speech.initialize(
//       onStatus: (status) => print('Status: $status'),
//       onError: (error) => print('Error: $error'),
//     );

//     if (available) {
//       startListening();  // Automatically start listening when initialized
//     } else {
//       print("Speech recognition not available.");
//     }
//   }

//   // Start listening and process commands
//   void startListening() {
//     if (_isListening) return;

//     _speech.listen(
//       onResult: (val) {
//         _lastCommand = val.recognizedWords.toLowerCase();
//         onCommandRecognized(_lastCommand);
//       },
//     );
//     _isListening = true;
//   }

//   // Stop listening
//   void stopListening() {
//     if (!_isListening) return;

//     _speech.stop();
//     _isListening = false;
//   }

//   // Restart listening
//   void restartListening() {
//     stopListening();
//     startListening();
//   }

//   // Dispose method to clean up resources
//   void dispose() {
//     stopListening();
//   }
// }

