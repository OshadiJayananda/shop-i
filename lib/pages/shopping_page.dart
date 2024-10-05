import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'cart_page.dart';

class ShoppingPage extends StatefulWidget {
  const ShoppingPage({super.key});

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  final DatabaseReference _productRef =
      FirebaseDatabase.instance.ref().child('products');
  final DatabaseReference _cartRef =
      FirebaseDatabase.instance.ref().child('cart');
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;

  Map<String, dynamic> products = {};
  Map<String, Map<String, dynamic>> cartItems = {};
  int _cartItemCount = 0;
  bool _isListening = false;
  String _lastCommand = '';

  String sanitizeKey(String key) {
    return key.replaceAll(' ', '').replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '');
  }

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initializeSpeechRecognition();
    _fetchProducts();
  }

  Future<void> _initializeSpeechRecognition() async {
    bool available = await _speech.initialize();
    if (!available) {
      await _speak("Speech recognition is not available.");
    }
  }

  Future<void> _fetchProducts() async {
    DataSnapshot snapshot = await _productRef.get();
    if (snapshot.value is Map) {
      final data = snapshot.value as Map;
      final fetchedProducts = <String, Map<String, dynamic>>{};

      data.forEach((key, value) {
        final itemData = Map<String, dynamic>.from(value);
        final itemName = itemData['Product Name'] as String?;
        final price = itemData['Price'] != null
            ? double.tryParse(itemData['Price'].toString())
            : 0.0;

        if (itemName != null) {
          fetchedProducts[itemName.toLowerCase()] = {'Price': price};
        } else {
          print("Product Name is missing for key: $key");
        }
      });

      setState(() {
        products = fetchedProducts;
      });

      print("Fetched products: $products");
    }
  }

  void _updateCartCount() {
    int count = cartItems.values
        .fold(0, (prev, item) => prev + (item['quantity'] as int));
    setState(() {
      _cartItemCount = count;
    });
  }

  Future<void> _startListening() async {
    if (_isListening) return; // Prevent starting if already listening

    try {
      bool available = await _speech.initialize(
        onStatus: (status) => print('Status: $status'),
        onError: (error) => print('Error: $error'),
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) {
          if (!mounted) return;
          setState(() {
            _lastCommand = val.recognizedWords.toLowerCase();
            print("Voice command recognized: $_lastCommand");
            _processVoiceCommand(_lastCommand);
          });
        });
      } else {
        print("Speech recognition is not available.");
      }
    } catch (e) {
      print("Error starting speech recognition: $e");
    }
  }

  void _processVoiceCommand(String command) {
    print("Processing voice command: $command");
    bool itemFound = false;

    command = command.trim(); // Trim the command for extra spaces
    RegExp commandPattern = RegExp(r'^(get|add|put)\s*(\d+)?\s*(.*)',
        caseSensitive: false); // Adjusted to include 'add' and 'put'
    int quantity = 1; // Default quantity is 1 if none provided

    final match = commandPattern.firstMatch(command);

    if (match != null) {
      // Extract the quantity if specified, else default to 1
      if (match.group(2) != null) {
        quantity = int.parse(match.group(2)!); // Use the captured quantity
      }

      // Extract the item name
      String itemName = match.group(3)?.toLowerCase() ?? '';

      // Check if the command is to show the cart
      if (command.contains("show list")) {
        print('show list command included');
        _handleShowCartCommand();
        return;
      }

      // Search for the item in the products list
      products.forEach((productName, details) {
        if (itemName.contains(productName.toLowerCase())) {
          // Compare in a case-insensitive way
          _addToCart(
              productName, quantity); // Add the item with specified quantity
          print(
              "$productName added to cart via voice command with quantity: $quantity.");
          itemFound = true;
          return;
        }
      });

      if (!itemFound) {
        // If no product matches the given name
        print("Item not found in the product list.");
        _speak("Item not available");
      } else {
        // Confirm the addition of the item(s) to the cart
        _speak("$quantity item(s) added to cart.");
      }
    } else {
      // If the voice command does not match the expected format
      _speak("Command not recognized. Please say 'get <quantity> <item>'");
    }
  }

  Future<void> _handleShowCartCommand() async {
    if (cartItems.isEmpty) {
      await _speak("Your cart is empty");
      print("Cart is empty.");
    } else {
      // Clear the existing cart in the database
      await _cartRef.remove();
      print("Existing cart items cleared from the database.");

      for (var entry in cartItems.entries) {
        String itemName = entry.key;
        Map<String, dynamic> itemData = entry.value;
        String sanitizedKey = sanitizeKey(itemName);

        print(
            "Adding $itemName to the cart database with quantity ${itemData['quantity']}");

        await _cartRef.child(sanitizedKey).set({
          'itemName': itemName,
          'quantity': itemData['quantity'],
          'price': itemData['price'],
          'totalPrice': itemData['totalPrice'],
        });
      }

      await _speak("Navigating to your cart");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CartPage(cartItems: cartItems),
        ),
      );
    }
  }

  void _addToCart(String itemName, [int quantity = 1]) {
    final price = products[itemName]?['Price'] ?? 0.0;

    setState(() {
      if (cartItems.containsKey(itemName)) {
        cartItems[itemName]!['quantity'] += quantity;
        cartItems[itemName]!['totalPrice'] = cartItems[itemName]!['price'] *
            cartItems[itemName]!['quantity']; // Recalculate totalPrice
      } else {
        cartItems[itemName] = {
          'price': price,
          'quantity': quantity,
          'totalPrice': price * quantity,
        };
      }
      _updateCartCount();
    });
    print("Added $quantity of $itemName to the cart. Cart now: $cartItems");
  }

  void _stopListening() async {
    if (!_isListening) return;

    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  Future<void> _speak(String message) async {
    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
    }

    await _flutterTts.speak(message);
    print("TTS Message: $message");
  }

  Widget _buildItemList() {
    if (products.isEmpty) {
      return const Center(
          child:
              CircularProgressIndicator()); // Show a loading indicator while fetching
    }

    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        String itemName = products.keys.elementAt(index);
        double price = products[itemName]['Price'];

        return ListTile(
          title: Text(itemName),
          subtitle: Text('Price: \$${price.toStringAsFixed(2)}'),
          trailing: IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            onPressed: () {
              _handleAddCommand('get 1 $itemName'); // Quick test
            },
          ),
        );
      },
    );
  }

  Future<void> _handleAddCommand(String command) async {
    print("Handling add command: $command");

    final itemNameRegex = RegExp(
        r'get\s*(\d+|one|two|three|four|five|six|seven|eight|nine|ten)?\s*(.*)',
        caseSensitive: false);
    final match = itemNameRegex.firstMatch(command);

    if (match != null) {
      String quantityText = match.group(1)?.trim() ?? "1";
      int quantity = _convertWordToNumber(quantityText);
      String itemName = match.group(2)!.trim().toLowerCase();

      await _speak('I recognized: $quantity $itemName.');

      if (products.containsKey(itemName)) {
        double price = products[itemName]['Price'];
        double totalPrice = price * quantity;

        setState(() {
          if (cartItems.containsKey(itemName)) {
            cartItems[itemName]!['quantity'] += quantity;
            cartItems[itemName]!['totalPrice'] = cartItems[itemName]!['price'] *
                cartItems[itemName]!['quantity'];
          } else {
            cartItems[itemName] = {
              'price': price,
              'quantity': quantity,
              'totalPrice': totalPrice,
            };
          }
          _updateCartCount();
        });

        String sanitizedKey = sanitizeKey(itemName);
        await _cartRef.child(sanitizedKey).set({
          'itemName': itemName,
          'quantity': cartItems[itemName]!['quantity'],
          'price': price,
          'totalPrice': cartItems[itemName]!['totalPrice'],
        });

        print("Added $itemName to cart with quantity: $quantity");
        await _speak("$quantity $itemName added to cart.");
      } else {
        print("Item not found: $itemName");
        await _speak("Sorry, $itemName is not available.");
      }
    } else {
      print("Invalid command format: $command");
      await _speak("I didn't understand the command.");
    }
  }

  int _convertWordToNumber(String word) {
    Map<String, int> wordToNumber = {
      'one': 1,
      'two': 2,
      'three': 3,
      'four': 4,
      'five': 5,
      'six': 6,
      'seven': 7,
      'eight': 8,
      'nine': 9,
      'ten': 10,
    };

    return wordToNumber[word.toLowerCase()] ?? int.tryParse(word) ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Page'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () async {
                  await _handleShowCartCommand();
                },
              ),
              if (_cartItemCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2.0),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16.0,
                      minHeight: 16.0,
                    ),
                    child: Text(
                      '$_cartItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
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
      body: _buildItemList(),
    );
  }
}
