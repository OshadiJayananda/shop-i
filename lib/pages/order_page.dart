import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'cash_page.dart'; // Import the CashPage

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> cartItems = [];

  double totalAmount = 0.0;
  String paymentMethod = 'Card'; // Default to Card
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
    _initializeTts();
    _speech = stt.SpeechToText();
  }

  // Initialize Text-to-Speech
  void _initializeTts() {
    _flutterTts = FlutterTts();
  }

  // Speak the total amount when navigating to the OrderPage
  Future<void> _speakTotalAmount() async {
    if (_flutterTts == null) {
      _initializeTts(); // Ensure TTS is initialized
    }
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak("The total amount is \$${totalAmount.toStringAsFixed(2)}");
  }

  // Load cart items from Firebase Realtime Database
  void _loadCartItems() {
    _database.child("cart").onValue.listen((event) {
      final data = event.snapshot.value;

      if (data == null) {
        setState(() {
          cartItems = [];
          totalAmount = 0.0;
        });
        return;
      }

      if (data is! Map) {
        setState(() {
          cartItems = [];
          totalAmount = 0.0;
        });
        return;
      }

      final Map<String, dynamic> dataMap = Map<String, dynamic>.from(data);
      final List<Map<String, dynamic>> fetchedCartItems = [];
      double total = 0.0;

      dataMap.forEach((key, value) {
        if (value is Map) {
          final itemName = value['itemName'] ?? 'Unknown';
          final totalPrice = double.tryParse(value['totalPrice']?.toString() ?? '0.0') ?? 0.0;
          final quantity = value['quantity'] as int? ?? 0;

          fetchedCartItems.add({
            'itemName': itemName,
            'quantity': quantity,
            'totalPrice': totalPrice,
          });

          total += totalPrice;
        }
      });

      setState(() {
        cartItems = fetchedCartItems;
        totalAmount = total;
      });

      // Speak the total amount when the cart is loaded
      _speakTotalAmount();
    });
  }

  // Start listening to voice commands
  void _startListening() async {
    if (_isListening) return; // Don't start listening if already listening

    bool available = await _speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) => print('onError: $val'),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) {
          _onSpeechResult(val.recognizedWords);
        },
      );
    }
  }

  // Stop listening to voice commands
  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  // Handle speech result
  void _onSpeechResult(String result) {
    if (result.toLowerCase().contains('cash payment')) {
      _handlePaymentMethod('Cash');
    } else if (result.toLowerCase().contains('card payment')) {
      _handlePaymentMethod('Card');
    } else if (result.toLowerCase().contains('do payment')) {
      _doPayment(); // Handle the do payment command
    }
  }

  // Handle payment method selection
  void _handlePaymentMethod(String? method) {
    if (method != null) {
      setState(() {
        paymentMethod = method;
      });
    }
  }

  // Handle payment
// Handle payment
void _doPayment() {
  if (paymentMethod == 'Cash') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CashPage(totalAmount: totalAmount)), // Pass the totalAmount here
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Payment of \$${totalAmount.toStringAsFixed(2)} via $paymentMethod'),
    ));
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Review"),
        actions: [
          _isListening
              ? IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: _stopListening,
                )
              : IconButton(
                  icon: const Icon(Icons.mic_none),
                  onPressed: _startListening,
                ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Item Name')),
                  DataColumn(label: Text('Quantity')),
                  DataColumn(label: Text('Total Price')),
                ],
                rows: cartItems.map((item) {
                  final itemName = item['itemName'] ?? 'No name';
                  final quantity = item['quantity'] ?? 0;
                  final totalPrice = item['totalPrice']?.toDouble() ?? 0.0;

                  return DataRow(cells: [
                    DataCell(Text(itemName)),
                    DataCell(Text('$quantity')),
                    DataCell(Text('\$${totalPrice.toStringAsFixed(2)}')),
                  ]);
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Amount: \$${totalAmount.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: _doPayment,
                  child: const Text("Do Payment"),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text("Card Payment"),
                    leading: Radio<String?>(
                      value: 'Card',
                      groupValue: paymentMethod,
                      onChanged: _handlePaymentMethod,
                    ),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text("Cash Payment"),
                    leading: Radio<String?>(
                      value: 'Cash',
                      groupValue: paymentMethod,
                      onChanged: _handlePaymentMethod,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
