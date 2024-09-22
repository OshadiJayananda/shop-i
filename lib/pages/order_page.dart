import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class OrderPage extends StatefulWidget {
  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final DatabaseReference _cartRef = FirebaseDatabase.instance.ref().child('cart');
  Map<String, Map<String, dynamic>> cartItems = {};
  double totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchCartItems(); // Fetch cart data on page load
  }

  // Fetch cart items from Firebase
  Future<void> _fetchCartItems() async {
    DataSnapshot snapshot = await _cartRef.get();
    print("Fetched cart: ${snapshot.value}");

    if (snapshot.value is Map) {
      final data = snapshot.value as Map;
      final fetchedCartItems = <String, Map<String, dynamic>>{};
      double calculatedTotalPrice = 0.0;
      data.forEach((key, value) {
        final itemData = Map<String, dynamic>.from(value);
        fetchedCartItems[key] = itemData;
        calculatedTotalPrice += itemData['totalPrice'] as double;
      });
      setState(() {
        cartItems = fetchedCartItems;
        totalPrice = calculatedTotalPrice;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Review'),
      ),
      body: cartItems.isEmpty
          ? const Center(child: Text('No items in the cart'))
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
                  child: Text(
                    'Total: \$${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
    );
  }
}
