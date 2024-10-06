import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';

class PromotionsPage extends StatefulWidget {
  // Add a named 'key' parameter to the constructor
  const PromotionsPage({super.key});  // Updated constructor

  @override
  _PromotionsPageState createState() => _PromotionsPageState();
}

class _PromotionsPageState extends State<PromotionsPage> {
  // Reference to the Firebase Realtime Database
  final DatabaseReference _promotionsRef = FirebaseDatabase.instance.ref().child('promotions');

  @override
  void initState() {
    super.initState();
    addPromotionsToFirebase();
  }

  // Method to add 50 hardcoded promotional items to Firebase
  void addPromotionsToFirebase() {
    // Helper function to generate random date between the given range
    String randomDate() {
      DateTime startDate = DateTime(2024, 9, 20);  // 20th Sep 2024
      DateTime endDate = DateTime(2024, 11, 30);   // 30th Nov 2024
      int daysDifference = endDate.difference(startDate).inDays;
      int randomDays = Random().nextInt(daysDifference + 1);  // Generate a random number of days
      DateTime randomStartDate = startDate.add(Duration(days: randomDays));
      DateTime randomEndDate = randomStartDate.add(Duration(days: Random().nextInt(7) + 1));  // Promotion duration 1-7 days
      return '${randomStartDate.toLocal().toString().split(' ')[0]} to ${randomEndDate.toLocal().toString().split(' ')[0]}';
    }

    // List of 50 promotional items
     List<Map<String, dynamic>> promotions = [
    //   {"item": "Apple", "promotion": "Buy 1 Get 1 Free", "discount": 50, "duration": randomDate(), "brand": "FreshFarm"},
    //   {"item": "Orange", "promotion": "20% Off", "discount": 20, "duration": randomDate(), "brand": "CitrusCo"},
    //   {"item": "Banana", "promotion": "Buy 2 Get 1 Free", "discount": 33, "duration": randomDate(), "brand": "TropicalBest"},
    //   {"item": "Grapes", "promotion": "15% Off", "discount": 15, "duration": randomDate(), "brand": "VineFresh"},
    //   {"item": "Strawberry", "promotion": "25% Off", "discount": 25, "duration": randomDate(), "brand": "BerryWorld"},
    //   {"item": "Milk", "promotion": "10% Off", "discount": 10, "duration": randomDate(), "brand": "DairyPure"},
    //   {"item": "Cheese", "promotion": "Buy 1 Get 1 Free", "discount": 50, "duration": randomDate(), "brand": "CheeseDelight"},
    //   {"item": "Yogurt", "promotion": "20% Off", "discount": 20, "duration": randomDate(), "brand": "YumYogurt"},
    //   {"item": "Chicken", "promotion": "15% Off", "discount": 15, "duration": randomDate(), "brand": "FarmFresh"},
    //   {"item": "Beef", "promotion": "20% Off", "discount": 20, "duration": randomDate(), "brand": "BeefBest"},
    //   {"item": "Fish", "promotion": "15% Off", "discount": 15, "duration": randomDate(), "brand": "OceanCatch"},
    //   {"item": "Eggs", "promotion": "Buy 1 Get 1 Free", "discount": 50, "duration": randomDate(), "brand": "EggFarm"},
    //   {"item": "Rice", "promotion": "10% Off", "discount": 10, "duration": randomDate(), "brand": "RiceGold"},
    //   {"item": "Pasta", "promotion": "Buy 2 Get 1 Free", "discount": 33, "duration": randomDate(), "brand": "ItalianBest"},
    //   {"item": "Bread", "promotion": "20% Off", "discount": 20, "duration": randomDate(), "brand": "FreshLoaf"},
    //   {"item": "Butter", "promotion": "15% Off", "discount": 15, "duration": randomDate(), "brand": "CreamyDelight"},
    //   {"item": "Ice Cream", "promotion": "Buy 1 Get 1 Free", "discount": 50, "duration": randomDate(), "brand": "ColdTreats"},
    //   {"item": "Juice", "promotion": "20% Off", "discount": 20, "duration": randomDate(), "brand": "FruitSplash"},
    //   {"item": "Water", "promotion": "Buy 1 Get 1 Free", "discount": 50, "duration": randomDate(), "brand": "AquaFresh"},
    //   {"item": "Soda", "promotion": "10% Off", "discount": 10, "duration": randomDate(), "brand": "FizzUp"},
    //   {"item": "Shampoo", "promotion": "Buy 2 Get 1 Free", "discount": 33, "duration": randomDate(), "brand": "HairCare"},
    //   {"item": "Soap", "promotion": "20% Off", "discount": 20, "duration": randomDate(), "brand": "CleanSkin"},
    //   {"item": "Toothpaste", "promotion": "15% Off", "discount": 15, "duration": randomDate(), "brand": "SmileBright"},
    //   {"item": "Tissues", "promotion": "Buy 1 Get 1 Free", "discount": 50, "duration": randomDate(), "brand": "SoftTouch"},
    //   {"item": "Detergent", "promotion": "20% Off", "discount": 20, "duration": randomDate(), "brand": "CleanUp"},
    //   {"item": "Dish Soap", "promotion": "15% Off", "discount": 15, "duration": randomDate(), "brand": "ShinyDishes"},
    //   {"item": "Bleach", "promotion": "10% Off", "discount": 10, "duration": randomDate(), "brand": "BrightWhite"},
    //   {"item": "Hand Wash", "promotion": "Buy 1 Get 1 Free", "discount": 50, "duration": randomDate(), "brand": "SafeHands"},
    //   {"item": "Deodorant", "promotion": "20% Off", "discount": 20, "duration": randomDate(), "brand": "FreshScent"},
    //   {"item": "Lotion", "promotion": "15% Off", "discount": 15, "duration": randomDate(), "brand": "SmoothSkin"},
    //   {"item": "Sunscreen", "promotion": "25% Off", "discount": 25, "duration": randomDate(), "brand": "SunGuard"},
    //   {"item": "Face Wash", "promotion": "Buy 2 Get 1 Free", "discount": 33, "duration": randomDate(), "brand": "FaceGlow"},
    //   {"item": "Shaving Cream", "promotion": "10% Off", "discount": 10, "duration": randomDate(), "brand": "SmoothShave"},
    //   {"item": "Razor", "promotion": "Buy 1 Get 1 Free", "discount": 50, "duration": randomDate(), "brand": "SharpEdge"},
    //   {"item": "Lip Balm", "promotion": "20% Off", "discount": 20, "duration": randomDate(), "brand": "LipCare"},
    //   {"item": "Makeup Remover", "promotion": "15% Off", "discount": 15, "duration": randomDate(), "brand": "CleanFace"},
    //   {"item": "Moisturizer", "promotion": "25% Off", "discount": 25, "duration": randomDate(), "brand": "SoftGlow"},
    //   {"item": "Shaving Razor", "promotion": "Buy 2 Get 1 Free", "discount": 33, "duration": randomDate(), "brand": "SharpShave"},
    //   {"item": "Conditioner", "promotion": "10% Off", "discount": 10, "duration": randomDate(), "brand": "SmoothLocks"},
    //   {"item": "Body Wash", "promotion": "Buy 1 Get 1 Free", "discount": 50, "duration": randomDate(), "brand": "CleanSkin"},
    //   {"item": "Hand Cream", "promotion": "20% Off", "discount": 20, "duration": randomDate(), "brand": "SoftTouch"},
    //   {"item": "Foot Cream", "promotion": "15% Off", "discount": 15, "duration": randomDate(), "brand": "FootCare"},
    //   {"item": "Perfume", "promotion": "25% Off", "discount": 25, "duration": randomDate(), "brand": "FragranceCo"},
    //   {"item": "Body Lotion", "promotion": "Buy 2 Get 1 Free", "discount": 33, "duration": randomDate(), "brand": "SkinSoft"},
    //   {"item": "Face Mask", "promotion": "10% Off", "discount": 10, "duration": randomDate(), "brand": "GlowSkin"},
    //   {"item": "Face Scrub", "promotion": "Buy 1 Get 1 Free", "discount": 50, "duration": randomDate(), "brand": "FreshFace"},
    //   {"item": "tifin", "promotion": "10% off", "discount": 30, "duration": randomDate(), "brand": "munchee"},

     ];

    // Add each promotion to Firebase
    for (var promotion in promotions) {
      _promotionsRef.push().set(promotion);
    }

    print('Promotions added to Firebase successfully');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotions Page'),
      ),
      body: const Center(
        child: Text('Promotions data uploaded to Firebase!'),
      ),
    );
  }
}
