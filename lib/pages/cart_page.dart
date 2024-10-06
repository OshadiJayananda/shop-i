import 'package:demo_app/pages/order_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class CartPage extends StatefulWidget {
  final Map<String, Map<String, dynamic>> cartItems;

  const CartPage({super.key, required this.cartItems});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final DatabaseReference _cartRef =
      FirebaseDatabase.instance.ref().child('cart');
  Map<String, Map<String, dynamic>> cartItems = {};
  late stt.SpeechToText _speechToText;
  bool _isListening = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    cartItems = widget.cartItems;
    _setupCartListener();
    _speechToText = stt.SpeechToText();
  }

  // Firebase listener to update cart in real-time
  void _setupCartListener() {
    _cartRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final dynamic data = event.snapshot.value;
        final updatedCartItems = <String, Map<String, dynamic>>{};

        if (data is Map) {
          data.forEach((key, value) {
            final itemData = Map<String, dynamic>.from(value);
            updatedCartItems[key] = itemData;
          });
        }

        setState(() {
          cartItems = updatedCartItems;
        });
      } else {
        setState(() {
          cartItems = {};
        });
      }
    });
  }

  // Total price calculator
  double _calculateTotalPrice() {
    return cartItems.values.fold(0.0, (sum, item) {
      final double totalPrice = (item['totalPrice'] as num?)?.toDouble() ?? 0.0;
      return sum + totalPrice;
    });
  }

  // Delete item from the cart with error handling
  Future<void> _deleteItem(String itemName) async {
    setState(() => _isLoading = true);
    try {
      await _cartRef.child(itemName).remove();
      setState(() {
        cartItems.remove(itemName);
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error deleting item')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Add or update item in the cart with error handling
  Future<void> _addOrUpdateItem(String itemName, double price) async {
    setState(() => _isLoading = true);
    try {
      if (cartItems.containsKey(itemName)) {
        final item = cartItems[itemName]!;
        final newQuantity = (item['quantity'] as int) + 1;
        final updatedTotal = newQuantity * price;

        await _cartRef.child(itemName).update({
          'quantity': newQuantity,
          'totalPrice': updatedTotal,
        });

        setState(() {
          cartItems[itemName] = {
            'price': price,
            'quantity': newQuantity,
            'totalPrice': updatedTotal,
          };
        });
      } else {
        const newQuantity = 1;
        final totalPrice = price * newQuantity;

        await _cartRef.child(itemName).set({
          'price': price,
          'quantity': newQuantity,
          'totalPrice': totalPrice,
        });

        setState(() {
          cartItems[itemName] = {
            'price': price,
            'quantity': newQuantity,
            'totalPrice': totalPrice,
          };
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error adding/updating item')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Improved command parsing and speech handling
  void _startListening() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(onResult: (result) {
          final recognizedWords = result.recognizedWords.toLowerCase();
          print("Recognized words: $recognizedWords");
          if (recognizedWords.contains("check out")) {
            print('checkout command');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OrderPage(),
              ),
            );
          } else if (recognizedWords.startsWith("delete")) {
            final itemName = recognizedWords.replaceFirst("delete", "").trim();
            if (cartItems.containsKey(itemName)) {
              _deleteItem(itemName);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Deleting $itemName")),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Item not found: $itemName")),
              );
            }
          } else if (recognizedWords.startsWith("add")) {
            // Command format: "add itemName at price"
            final parts = recognizedWords.split(" ");
            if (parts.length >= 4) {
              final itemName = parts[1];
              final price = double.tryParse(parts[3]);
              if (price != null) {
                _addOrUpdateItem(itemName, price);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Added $itemName")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Invalid price format")),
                );
              }
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Command not recognized")),
            );
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Speech recognition not available")),
        );
      }
    }
  }

  // Stop listening for voice commands
  void _stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    }
  }

  // Widget to build the data table row for each item
  DataRow _buildCartItemRow(String itemName, Map<String, dynamic> item) {
    final int quantity = (item['quantity'] as num?)?.toInt() ?? 1;
    final double price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final double totalPrice =
        (item['totalPrice'] as num?)?.toDouble() ?? (price * quantity);

    return DataRow(cells: [
      DataCell(Text(itemName)),
      DataCell(Text(quantity.toString())),
      DataCell(Text('\$${price.toStringAsFixed(2)}')),
      DataCell(Text('\$${totalPrice.toStringAsFixed(2)}')),
      DataCell(
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteItem(itemName),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
              ? const Center(child: Text('Your cart is empty'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Item Name')),
                              DataColumn(label: Text('Quantity')),
                              DataColumn(label: Text('Price')),
                              DataColumn(label: Text('Total')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: cartItems.entries.map((entry) {
                              return _buildCartItemRow(entry.key, entry.value);
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
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const OrderPage(),
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
