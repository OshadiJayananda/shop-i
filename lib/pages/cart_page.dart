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

  // Delete item from Firebase and UI
  Future<void> _deleteItem(String itemName) async {
    await _cartRef.child(itemName).remove(); // Delete item from Firebase
    setState(() {
      cartItems.remove(itemName); // Remove item from UI
    });
  }

  // Start listening to voice commands
  void _startListening() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(onResult: (result) {
          final recognizedWords = result.recognizedWords.toLowerCase();
          print("Recognized words: $recognizedWords"); // Print recognized words for debugging

          // Check for 'checkout' command
          if (recognizedWords.contains("check out")) {
            print('checkout command');
            // ScaffoldMessenger.of(context).showSnackBar(
            //   // const SnackBar(content: Text("Checkout command received")),
            // ); // Show snackbar for feedback
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OrderPage(), // Navigate to OrderPage
              ),
            );
          } 
          // Check for 'delete' command
          else if (recognizedWords.startsWith("delete")) {
            final itemName = recognizedWords.replaceFirst("delete", "").trim(); // Extract item name
            if (cartItems.containsKey(itemName)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Deleting $itemName")),
              ); // Show snackbar for delete feedback
              _deleteItem(itemName); // Delete the item
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Item not found: $itemName")),
              );
            }
          } 
          // Fallback message if command not recognized
          else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Command not recognized")),
            );
          }
        });
      }
    }
  }

  // Stop listening to voice commands
  void _stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          // Toggle microphone icon based on _isListening state
          if (_isListening)
            IconButton(
              icon: const Icon(Icons.mic),
              onPressed: _stopListening,
            )
          else
            IconButton(
              icon: const Icon(Icons.mic_none),
              onPressed: _startListening,
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal, // Enable horizontal scrolling
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Item Name')),
                          DataColumn(label: Text('Quantity')),
                          DataColumn(label: Text('Price')),
                          DataColumn(label: Text('Total')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: cartItems.entries.map((entry) {
                          String itemName = entry.key;
                          final item = entry.value;

                          // Use fallback values for price and totalPrice if they are null
                          int quantity = item['quantity'] as int? ?? 1; // Default to 1 if null
                          double price = (item['price'] as double?) ?? 0.0; // Default to 0.0 if null
                          double totalPrice = price * quantity;// Default to 0.0 if null

                          return DataRow(cells: [
                            DataCell(Text(itemName)),
                            DataCell(Text(quantity.toString())),
                            DataCell(Text('\$${price.toStringAsFixed(2)}')),
                            DataCell(Text('\$${totalPrice.toStringAsFixed(2)}')),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _deleteItem(itemName); // Delete item
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
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