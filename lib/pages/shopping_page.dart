import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'cart_page.dart'; // Import CartPage

class ShoppingPage extends StatefulWidget {
  const ShoppingPage({super.key});

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  final DatabaseReference _itemRef = FirebaseDatabase.instance.ref().child('items');
  final DatabaseReference _cartRef = FirebaseDatabase.instance.ref().child('cart');
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;

  Map<String, dynamic> items = {}; // For holding fetched items
  // Map<String, Map<String, dynamic>> cart = {}; // Cart items with price and total price
Map<String, Map<String, dynamic>> cartItems = {};

  int _cartItemCount = 0; 
  bool _isListening = false; // To track the listening state

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _fetchItems();
    _initSpeechRecognition();
  }

  // Fetch items from the Firebase database
  Future<void> _fetchItems() async {
    DataSnapshot snapshot = await _itemRef.get();
    print("Fetched items: ${snapshot.value}");
    if (snapshot.value is Map) {
      final data = snapshot.value as Map;
      final fetchedItems = <String, Map<String, dynamic>>{};
      data.forEach((key, value) {
        final itemData = Map<String, dynamic>.from(value);
        final itemName = itemData['itemName'] as String;
        final price = itemData['price'] as double;
        fetchedItems[itemName.toLowerCase()] = {'price': price};
      });
      setState(() {
        items = fetchedItems;
      });
    }
  }


  // Update cart item count
void _updateCartCount() {
int count = cartItems.values.fold(0, (prev, item) => prev + (item['quantity'] as int));
  setState(() {
    _cartItemCount = count;
  });
}


  // Initialize speech recognition
  void _initSpeechRecognition() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() {
        _startListening();
      });
    } else {
      print('Speech recognition is not available');
    }
  }

  // Start listening for voice commands
void _startListening() async {
  if (_isListening) return;

  try {
    await _speech.listen(onResult: (result) {
      String command = result.recognizedWords.toLowerCase().trim();
      
      // Print the recognized command for debugging
      print('Recognized command: $command');
      
      // Check if key words 'show' and 'cart' are in the command
      if (_containsKeywords(command, ['show', 'cart'])) {
        print('Detected "show cart" command'); // Debugging print
        _handleShowCartCommand();
      } else if (_containsKeywords(command, ['add', 'cart'])) {
        print('Detected "add to cart" command'); // Debugging print
        _handleAddCommand(command);

      } else {
        print('Unrecognized command'); // Debugging print
      }
    });
    setState(() {
      _isListening = true;
    });
  } catch (e) {
    print('Error starting speech recognition: $e');
  }
}



// Helper function to check for keywords in the command
bool _containsKeywords(String command, List<String> keywords) {
  for (String keyword in keywords) {
    if (!command.contains(keyword)) {
      return false;
    }
  }
  return true;
}






  // Stop listening
  void _stopListening() async {
    if (!_isListening) return; // Avoid stopping if not listening

    try {
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
    } catch (e) {
      print('Error stopping speech recognition: $e');
    }
  }

  @override
  void dispose() {
    _stopListening(); // Ensure listening is stopped when widget is disposed
    super.dispose();
  }

  // Handle adding items and quantities to the cart
  Future<void> _handleAddCommand(String command) async {
    final itemNameRegex = RegExp(r'add (\d+)?\s?(.*?)\s?to the cart', caseSensitive: false);
    final match = itemNameRegex.firstMatch(command);

    if (match != null) {
      int quantity = match.group(1) != null ? int.parse(match.group(1)!) : 1;
      String itemName = match.group(2)!.trim().toLowerCase();

      print("Command parsed: itemName = $itemName, quantity = $quantity");

      if (items.containsKey(itemName)) {
        final price = items[itemName]['price'] as double;
        final totalPrice = price * quantity;


        setState(() {
          if (cartItems.containsKey(itemName)) {
            cartItems[itemName]!['quantity'] = (cartItems[itemName]!['quantity'] ?? 0) + quantity;
            cartItems[itemName]!['totalPrice'] = (cartItems[itemName]!['quantity'] as int) * price;
          } else {
            cartItems[itemName] = {
              'price': price,
              'quantity': quantity,
              'totalPrice': totalPrice,
            };
          }
          _updateCartCount(); // Update cart item count
        });
await _speak('$quantity $itemName added to the cart');      
} else {
    await    _speak('$itemName is not available');
      }
    } else {
    await  _speak('Could not understand the command. Please try again.');
    }
  }


  // Handle navigating to CartPage and saving items to the cart database
  Future<void> _handleShowCartCommand() async {
    try {
      print("Saving cart: $cartItems");

      // Save the cart data to Firebase
      await _cartRef.set(cartItems);

      await _speak("Navigating to your cart");

      // Ensure the CartPage can handle empty or populated cart
      Navigator.push(
        context,
        MaterialPageRoute(
builder: (context) => CartPage(cartItems: cartItems),
        ),
      );
       print("Navigation to CartPage successful"); 
    } catch (e) {
      print("Error saving cart: $e");
      _speak("There was an error saving the cart.");
    }
  }

  // Text-to-speech feedback
  Future<void> _speak(String message) async {
    await _flutterTts.speak(message);

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
                onPressed: () {
                  _handleShowCartCommand(); // Navigate to CartPage when cart icon is clicked
                },
              ),
              if (_cartItemCount > 0)
                Positioned(
                  right: 0,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.red,
                    child: Text(
                      _cartItemCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),

      body: _buildItemList(),
    );
  }

  Widget _buildItemList() {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        String itemName = items.keys.elementAt(index);
        String price = items[itemName]['price'].toString();

        return ListTile(
          title: Text(itemName),
          subtitle: Text('Price: $price'),
          trailing: IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            onPressed: () {
              _handleAddCommand('add 1 $itemName to the cart');
            },

          ),
        );
      },
    );
  }
}