import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  // Function to fetch cart items from Firebase
  void _loadCartItems() {
    _database.child("cart").onValue.listen((event) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final List<Map<String, dynamic>> fetchedCartItems = [];

      data.forEach((key, value) {
        fetchedCartItems.add({
          'key': key, // Adding the key for later use (e.g., for deletion)
          'itemName': value['itemName'],
          'price': double.tryParse(value['price']) ?? 0.0, // Convert price to double
          'quantity': value['quantity'] as int,
        });
      });

      setState(() {
        cartItems = fetchedCartItems;
      });
    });
  }

  // Function to update the quantity in Firebase
  void _updateQuantity(String key, int quantity) {
    _database.child("cart/$key/quantity").set(quantity);
  }

  // Function to delete an item from Firebase
  void _deleteItem(String key) {
    _database.child("cart/$key").remove();
  }

  // Function to calculate the total amount
  double _calculateTotalAmount() {
    return cartItems.fold(0.0, (total, item) {
      return total + (item['price'] as double) * (item['quantity'] as int);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cart"),
      ),
      body: Column(
        children: [
          Expanded(
            child: cartItems.isNotEmpty
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Item Name')),
                        DataColumn(label: Text('Quantity')),
                        DataColumn(label: Text('Unit Price')),
                        DataColumn(label: Text('Total')),
                        DataColumn(label: Text('Action')),
                      ],
                      rows: cartItems.map((cartItem) {
                        final unitPrice = cartItem['price'] as double;
                        final quantity = cartItem['quantity'] as int;
                        final total = unitPrice * quantity;

                        return DataRow(
                          cells: [
                            DataCell(Text(cartItem['itemName'])),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      if (quantity > 1) {
                                        _updateQuantity(cartItem['key'], quantity - 1);
                                      }
                                    },
                                  ),
                                  Text(quantity.toString()),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      _updateQuantity(cartItem['key'], quantity + 1);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            DataCell(Text('\$${unitPrice.toStringAsFixed(2)}')),
                            DataCell(Text('\$${total.toStringAsFixed(2)}')),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _deleteItem(cartItem['key']);
                                },
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  )
                : const Center(child: Text("Your cart is empty")),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Total Amount: \$${_calculateTotalAmount().toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Handle the navigation to checkout page
                    Navigator.pushNamed(context, '/checkout');
                  },
                  child: const Text('Proceed to Checkout'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
