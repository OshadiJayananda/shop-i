// import 'package:flutter/material.dart';
// import 'package:flutter_tts/flutter_tts.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;

// class CardPage extends StatefulWidget {
//   final double totalAmount;

//   const CardPage({super.key, required this.totalAmount});

//   @override
//   State<CardPage> createState() => _CardPageState();
// }

// class _CardPageState extends State<CardPage> {
//   final _cardNumberController = TextEditingController();
//   final _expiryDateController = TextEditingController();
//   final _cvvController = TextEditingController();

//   final FlutterTts flutterTts = FlutterTts();
//   late stt.SpeechToText _speech;
//   bool _isListening = false;
//   String _currentField = '';

//   bool _isProcessingPayment = false;

//   @override
//   void initState() {
//     super.initState();
//     _speech = stt.SpeechToText();
//     _speak("Please provide your card details starting with the card number.");
//   }

//   Future<void> _speak(String text) async {
//     await flutterTts.speak(text);
//   }

//   void _startListening(String field) async {
//     _currentField = field;
//     if (!_isListening) {
//       bool available = await _speech.initialize();
//       if (available) {
//         setState(() => _isListening = true);
//         _speech.listen(onResult: (result) {
//           if (field == 'cardNumber') {
//             _cardNumberController.text = result.recognizedWords;
//             _speak("You said card number: ${_cardNumberController.text}. Now provide the expiry date.");
//             _startListening('expiryDate');
//           } else if (field == 'expiryDate') {
//             _expiryDateController.text = result.recognizedWords;
//             _speak("You said expiry date: ${_expiryDateController.text}. Now provide the CVV.");
//             _startListening('cvv');
//           } else if (field == 'cvv') {
//             _cvvController.text = result.recognizedWords;
//             _speak("You said CVV: ${_cvvController.text}. Confirming payment now.");
//             _processPayment();
//           }
//         });
//       }
//     }
//   }

//   void _stopListening() {
//     if (_isListening) {
//       _speech.stop();
//       setState(() => _isListening = false);
//     }
//   }

//   void _processPayment() {
//     setState(() {
//       _isProcessingPayment = true;
//     });

//     // Simulate card payment processing
//     Future.delayed(const Duration(seconds: 2), () {
//       setState(() {
//         _isProcessingPayment = false;
//       });

//       // Assuming success in this example
//       _speak("Payment of ${widget.totalAmount.toStringAsFixed(2)} dollars processed successfully.");

//       // Show confirmation of payment
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text('Payment of \$${widget.totalAmount.toStringAsFixed(2)} processed successfully'),
//       ));

//       // Navigate back to a home screen or any confirmation page
//       Navigator.pop(context); // This will pop to the previous screen
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Card Payment'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: _cardNumberController,
//               decoration: const InputDecoration(labelText: 'Card Number'),
//               keyboardType: TextInputType.number,
//             ),
//             TextField(
//               controller: _expiryDateController,
//               decoration: const InputDecoration(labelText: 'Expiry Date'),
//               keyboardType: TextInputType.datetime,
//             ),
//             TextField(
//               controller: _cvvController,
//               decoration: const InputDecoration(labelText: 'CVV'),
//               obscureText: true,
//               keyboardType: TextInputType.number,
//             ),
//             const SizedBox(height: 20),
//             _isProcessingPayment
//                 ? const CircularProgressIndicator()
//                 : ElevatedButton(
//                     onPressed: () {
//                       _speak("Please provide your card number.");
//                       _startListening('cardNumber');
//                     },
//                     child: const Text('Start Voice Input'),
//                   ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _cardNumberController.dispose();
//     _expiryDateController.dispose();
//     _cvvController.dispose();
//     flutterTts.stop();
//     super.dispose();
//   }
// }
