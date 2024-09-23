import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> cartItems = [];
  double totalAmount = 0.0;
  String paymentMethod = 'Card';

  @override
  void initState() {
    super.initState();
    _loadCartItems();
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
    });
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
  void _doPayment() {
    // Implement payment logic here
    // For now, just show a confirmation
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Payment of \$${totalAmount.toStringAsFixed(2)} via $paymentMethod'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order Review")),
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