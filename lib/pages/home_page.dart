import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final database = FirebaseDatabase.instance.ref();
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final itemsRef = database.child("/items");
    
    return Scaffold(
      appBar: AppBar(title: Text("Add Data")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              TextField(
                controller: itemNameController,
                decoration: InputDecoration(
                  labelText: "Item Name",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: "Price",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final itemName = itemNameController.text;
                  final price = priceController.text;

                  if (itemName.isNotEmpty && price.isNotEmpty) {
                    try {
                      await itemsRef.push().set({
                        'itemName': itemName,
                        'price': price,
                      });
                      print("Data added successfully");
                      // Clear the text fields after successful addition
                      itemNameController.clear();
                      priceController.clear();
                    } catch (e) {
                      print("Error adding data: $e");
                    }
                  } else {
                    print("Please enter both item name and price");
                  }
                },
                child: Text("Add Data"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
