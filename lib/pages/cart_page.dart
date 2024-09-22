import 'package:demo_app/pages/order_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class CartPage extends StatefulWidget {
  final Map<String, Map<String, dynamic>> cartItems; // Accept cart items from ShoppingPage

  const CartPage({super.key, required this.cartItems});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final DatabaseReference _cartRef = FirebaseDatabase.instance.ref().child('cart');
  Map<String, Map<String, dynamic>> cartItems = {};
  late stt.SpeechToText _speechToText;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    cartItems = widget.cartItems; // Initialize with passed cart items
    _fetchCartItems(); // Fetch the latest cart data from Firebase
    _speechToText = stt.SpeechToText(); // Initialize speech to text
    _listenToVoiceCommands();
  }

  // Fetch cart items from Firebase
  Future<void> _fetchCartItems() async {
    DataSnapshot snapshot = await _cartRef.get();
    print("Fetched cart: ${snapshot.value}");

    if (snapshot.value is Map) {
      final data = snapshot.value as Map;
      final fetchedCartItems = <String, Map<String, dynamic>>{};
      data.forEach((key, value) {
        final itemData = Map<String, dynamic>.from(value);
        fetchedCartItems[key] = itemData;
      });
      setState(() {
        cartItems = fetchedCartItems; // Update cart items with fetched data
      });
    }
  }

  // Calculate total cart price
  double _calculateTotalPrice() {
    return cartItems.values.fold(0.0, (sum, item) {
      final totalPrice = item['totalPrice'] as double;
      return sum + totalPrice;
    });
  }

  // Voice command listener
  void _listenToVoiceCommands() async {
    bool available = await _speechToText.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speechToText.listen(onResult: (result) {
        if (result.recognizedWords.toLowerCase() == "checkout") {
          // Navigate to OrderPage when "checkout" command is detected
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderPage(), // Navigate to OrderPage
            ),
          );
        }
      });
    } else {
      setState(() => _isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
      ),
      body: cartItems.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      String itemName = cartItems.keys.elementAt(index);
                      final item = cartItems[itemName]!;
                      int quantity = item['quantity'] as int;
                      double price = item['price'] as double;
                      double totalPrice = item['totalPrice'] as double;

                      return ListTile(
                        title: Text(itemName),
                        subtitle: Text('Quantity: $quantity\nPrice: \$${price.toStringAsFixed(2)}'),
                        trailing: Text('Total: \$${totalPrice.toStringAsFixed(2)}'),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: \$${_calculateTotalPrice().toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Manually navigate to OrderPage when the button is pressed
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderPage(),
                            ),
                          );
                        },
                        child: const Text('Checkout'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}