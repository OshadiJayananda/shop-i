import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class CashPage extends StatefulWidget {
  final double totalAmount; // Accept totalAmount as a parameter

  const CashPage({super.key, required this.totalAmount});

  @override
  State<CashPage> createState() => _CashPageState();
}

class _CashPageState extends State<CashPage> {
  late FlutterTts _flutterTts;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _speakReceipt();
  }

  // Initialize Text-to-Speech
  void _initializeTts() {
    _flutterTts = FlutterTts();
  }

  // Speak the receipt details
  Future<void> _speakReceipt() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak("Your total amount is \$${widget.totalAmount.toStringAsFixed(2)}. Your payment is successful. Have a nice day! Come again!");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Receipt"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Receipt",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              "Total Amount: \$${widget.totalAmount.toStringAsFixed(2)}",
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            const Text(
              "Thank you for your payment!",
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
