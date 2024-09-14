import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt; // Import the speech_to_text package
import 'cart_page.dart'; // Import the CartPage

class ShoppingPage extends StatefulWidget {
  const ShoppingPage({super.key});

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  final _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> items = [];
  Map<String, int> cartItems = {}; // To store itemName and quantity
  int cartCount = 0; // Tracks number of items in cart

  late stt.SpeechToText _speech; // Speech recognition object
  bool _isListening = false;
  String _lastCommand = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _activateListeners();
  }

  void _activateListeners() {
    _database.child("items").onValue.listen((event) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final List<Map<String, dynamic>> fetchedItems = [];

      data.forEach((key, value) {
        fetchedItems.add({
          'itemName': value['itemName'],
          'price': value['price'],
        });
      });

      setState(() {
        items = fetchedItems;
      });
    });
  }

  // Function to handle adding items to cart with an initial quantity of 1
  void _addToCart(String itemName, [int quantity = 1]) {
    setState(() {
      cartItems[itemName] = cartItems.containsKey(itemName)
          ? cartItems[itemName]! + quantity
          : quantity;
      cartCount = cartItems.length;
    });
  }

  // Function to increase quantity of an item in the cart
  void _increaseQuantity(String itemName) {
    setState(() {
      cartItems[itemName] = cartItems[itemName]! + 1;
    });
  }

  // Function to decrease quantity of an item in the cart
  void _decreaseQuantity(String itemName) {
    setState(() {
      if (cartItems[itemName]! > 1) {
        cartItems[itemName] = cartItems[itemName]! - 1;
      } else {
        cartItems.remove(itemName); // Remove item from cart if quantity is 0
        cartCount = cartItems.length;
      }
    });
  }

  // Function to save cart items to Firebase "cart" table
  Future<void> _saveCartToDatabase() async {
    final cartRef = _database.child("cart");

    try {
      await cartRef.remove(); // Clear existing cart data

      // Save each cart item to Firebase
      cartItems.forEach((itemName, quantity) async {
        final itemData = items.firstWhere((item) => item['itemName'] == itemName);
        final price = itemData['price'];

        await cartRef.push().set({
          'itemName': itemName,
          'price': price,
          'quantity': quantity,
        });
      });

      print("Cart items saved to Firebase successfully.");
    } catch (e) {
      print("Error saving cart to Firebase: $e");
    }
  }

  // Start listening for voice commands
  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Status: $status'),
      onError: (error) => print('Error: $error'),
    );
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (val) {
        setState(() {
          _lastCommand = val.recognizedWords.toLowerCase();
          _processVoiceCommand(_lastCommand); // Process the voice command
        });
      });
    }
  }

  // Stop listening for voice commands
  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  // Process the voice command to add an item to the cart
  void _processVoiceCommand(String command) {
    bool itemFound = false;

    for (var item in items) {
      if (command.contains(item['itemName'].toLowerCase())) {
        _addToCart(item['itemName']); // Add the item to the cart
        print("${item['itemName']} added to cart via voice command.");
        itemFound = true;
        break;
      }
    }

    if (!itemFound) {
      _showMessage("Item not available");
      print("Item not available in the database.");
    }
  }

  // Show a message when the item is not found
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shopping"),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  _saveCartToDatabase(); // Save cart items to Firebase
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartPage()),
                  );
                },
              ),
              if (cartCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: items.isNotEmpty
                ? Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, // 3 columns
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final itemName = items[index]['itemName'];
                        final itemPrice = items[index]['price'];

                        return Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  itemName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text("Price: $itemPrice"),
                                const Spacer(),
                                cartItems.containsKey(itemName)
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            onPressed: () {
                                              _decreaseQuantity(itemName);
                                            },
                                            icon: const Icon(Icons.remove),
                                          ),
                                          Text(cartItems[itemName].toString()),
                                          IconButton(
                                            onPressed: () {
                                              _increaseQuantity(itemName);
                                            },
                                            icon: const Icon(Icons.add),
                                          ),
                                        ],
                                      )
                                    : ElevatedButton(
                                        onPressed: () {
                                          _addToCart(itemName);
                                          print('$itemName added to cart');
                                        },
                                        child: const Text("Add to Cart"),
                                      ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : const Text("No items available"),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isListening ? _stopListening : _startListening,
            child: Text(_isListening ? 'Stop Listening' : 'Start Voice Command'),
          ),
        ],
      ),
    );
  }
}
