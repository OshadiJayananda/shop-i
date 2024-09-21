import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _database = FirebaseDatabase.instance.ref();

  final _productNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _brandController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _locationController = TextEditingController();
  final _locations = [
    'Aisle 1, Shelf 1',
    'Aisle 1, Shelf 2',
    'Aisle 1, Shelf 3',
    'Aisle 2, Shelf 1',
    'Aisle 2, Shelf 2',
    'Aisle 2, Shelf 3',
  ];
  String? _selectedLocation;

  @override
  void dispose() {
    _productNameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveProductToDatabase({
    required String key,
    required String productName,
    required String description,
    required String category,
    required String brand,
    required double price,
    required int stock,
    required String location,
  }) async {
    // Reference to the 'product' node in the database using the unique key
    final productRef = _database.child("products").child(key);

    try {
      // Optional: Uncomment if you want to clear existing product data
      // await productRef.remove();

      // Save the product to Firebase
      await productRef.set({
        'productName': productName,
        'description': description,
        'category': category,
        'brand': brand,
        'price': price,
        'stock': stock,
        'location': location,
      });

      print("Product saved to Firebase successfully.");
    } catch (e) {
      // Re-throw the exception to be caught in _submitForm
      throw Exception("Error saving product to Firebase: $e");
    }
  }

  String _generateUniqueKey(String productName, String brand) {
    // Generate a unique key by combining product name and brand
    return '${productName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_')}_${brand.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';
  }

  /* 
  // Dummy data for products
  final List<Map<String, dynamic>> products = [
    {
      "Product Name": "Wireless Mouse",
      "Description":
          "A sleek and ergonomic wireless mouse with a USB receiver.",
      "Category": "Electronics",
      "Brand": "Logitech",
      "Price": 25.99,
      "Stock": 150,
      "Location": "Aisle 1, Shelf 1"
    },
    {
      "Product Name": "Bluetooth Headphones",
      "Description": "Over-ear Bluetooth headphones with noise cancellation.",
      "Category": "Electronics",
      "Brand": "Sony",
      "Price": 199.99,
      "Stock": 75,
      "Location": "Aisle 1, Shelf 2"
    },
    {
      "Product Name": "4K LED TV",
      "Description": "55-inch 4K Ultra HD LED television with smart features.",
      "Category": "Electronics",
      "Brand": "Samsung",
      "Price": 499.99,
      "Stock": 50,
      "Location": "Aisle 1, Shelf 3"
    },
    {
      "Product Name": "Men's Running Shoes",
      "Description": "Comfortable running shoes designed for daily exercise.",
      "Category": "Clothing",
      "Brand": "Nike",
      "Price": 89.99,
      "Stock": 200,
      "Location": "Aisle 2, Shelf 1"
    },
    {
      "Product Name": "Organic Almonds",
      "Description": "Raw organic almonds, perfect for snacking or cooking.",
      "Category": "Groceries",
      "Brand": "Blue Diamond",
      "Price": 15.99,
      "Stock": 300,
      "Location": "Aisle 2, Shelf 2"
    },
    {
      "Product Name": "Yoga Mat",
      "Description": "Non-slip yoga mat with extra cushioning for comfort.",
      "Category": "Sports",
      "Brand": "Liforme",
      "Price": 39.99,
      "Stock": 120,
      "Location": "Aisle 2, Shelf 3"
    },
    {
      "Product Name": "Stainless Steel Water Bottle",
      "Description": "Durable and insulated water bottle with leak-proof cap.",
      "Category": "Sports",
      "Brand": "Hydro Flask",
      "Price": 29.99,
      "Stock": 100,
      "Location": "Aisle 1, Shelf 1"
    },
    {
      "Product Name": "Leather Wallet",
      "Description": "High-quality leather wallet with multiple card slots.",
      "Category": "Accessories",
      "Brand": "Bellroy",
      "Price": 89.95,
      "Stock": 80,
      "Location": "Aisle 1, Shelf 2"
    },
    {
      "Product Name": "Office Chair",
      "Description":
          "Ergonomic office chair with adjustable height and lumbar support.",
      "Category": "Furniture",
      "Brand": "Herman Miller",
      "Price": 699.00,
      "Stock": 30,
      "Location": "Aisle 2, Shelf 1"
    },
    {
      "Product Name": "Electric Toothbrush",
      "Description":
          "Rechargeable electric toothbrush with multiple brushing modes.",
      "Category": "Health",
      "Brand": "Philips",
      "Price": 119.99,
      "Stock": 60,
      "Location": "Aisle 1, Shelf 3"
    },
    {
      "Product Name": "Camping Tent",
      "Description":
          "Four-person camping tent with waterproof and wind-resistant features.",
      "Category": "Outdoor",
      "Brand": "Coleman",
      "Price": 129.99,
      "Stock": 45,
      "Location": "Aisle 2, Shelf 2"
    },
    {
      "Product Name": "Blender",
      "Description":
          "High-power blender for making smoothies, soups, and sauces.",
      "Category": "Appliances",
      "Brand": "Vitamix",
      "Price": 399.99,
      "Stock": 70,
      "Location": "Aisle 1, Shelf 1"
    },
    {
      "Product Name": "Men's Leather Jacket",
      "Description":
          "Stylish leather jacket with a slim fit and zippered pockets.",
      "Category": "Clothing",
      "Brand": "AllSaints",
      "Price": 299.99,
      "Stock": 40,
      "Location": "Aisle 1, Shelf 2"
    },
    {
      "Product Name": "Smartwatch",
      "Description":
          "Smartwatch with fitness tracking, notifications, and GPS.",
      "Category": "Electronics",
      "Brand": "Apple",
      "Price": 399.00,
      "Stock": 85,
      "Location": "Aisle 1, Shelf 3"
    },
    {
      "Product Name": "Gourmet Coffee Beans",
      "Description":
          "Freshly roasted coffee beans for a rich and aromatic brew.",
      "Category": "Groceries",
      "Brand": "Lavazza",
      "Price": 12.99,
      "Stock": 250,
      "Location": "Aisle 2, Shelf 1"
    },
    {
      "Product Name": "Digital Camera",
      "Description":
          "High-resolution digital camera with interchangeable lenses.",
      "Category": "Electronics",
      "Brand": "Canon",
      "Price": 799.99,
      "Stock": 35,
      "Location": "Aisle 1, Shelf 2"
    },
    {
      "Product Name": "Cookware Set",
      "Description": "Non-stick cookware set including pots, pans, and lids.",
      "Category": "Appliances",
      "Brand": "T-fal",
      "Price": 159.99,
      "Stock": 55,
      "Location": "Aisle 1, Shelf 3"
    },
    {
      "Product Name": "Wireless Keyboard",
      "Description": "Compact wireless keyboard with long battery life.",
      "Category": "Electronics",
      "Brand": "Logitech",
      "Price": 49.99,
      "Stock": 90,
      "Location": "Aisle 2, Shelf 1"
    },
    {
      "Product Name": "Leather Briefcase",
      "Description":
          "Elegant leather briefcase with multiple compartments for business use.",
      "Category": "Accessories",
      "Brand": "Tumi",
      "Price": 249.95,
      "Stock": 60,
      "Location": "Aisle 1, Shelf 2"
    },
    {
      "Product Name": "Air Purifier",
      "Description": "Air purifier with HEPA filter for clean and fresh air.",
      "Category": "Home",
      "Brand": "Dyson",
      "Price": 499.00,
      "Stock": 20,
      "Location": "Aisle 2, Shelf 3"
    },
    {
      "Product Name": "Fitness Tracker",
      "Description":
          "Wearable fitness tracker with heart rate monitoring and sleep analysis.",
      "Category": "Electronics",
      "Brand": "Fitbit",
      "Price": 149.99,
      "Stock": 110,
      "Location": "Aisle 1, Shelf 1"
    },
    {
      "Product Name": "Electric Kettle",
      "Description": "Rapid boil electric kettle with automatic shut-off.",
      "Category": "Appliances",
      "Brand": "Breville",
      "Price": 79.99,
      "Stock": 95,
      "Location": "Aisle 2, Shelf 2"
    },
    {
      "Product Name": "Portable Speaker",
      "Description":
          "Compact portable speaker with Bluetooth connectivity and waterproof design.",
      "Category": "Electronics",
      "Brand": "Bose",
      "Price": 129.99,
      "Stock": 80,
      "Location": "Aisle 1, Shelf 3"
    },
    {
      "Product Name": "Hand Cream",
      "Description": "Moisturizing hand cream with shea butter and vitamin E.",
      "Category": "Personal Care",
      "Brand": "L'Occitane",
      "Price": 24.00,
      "Stock": 200,
      "Location": "Aisle 2, Shelf 1"
    },
    {
      "Product Name": "Backpack",
      "Description":
          "Durable backpack with padded straps and multiple compartments.",
      "Category": "Accessories",
      "Brand": "North Face",
      "Price": 89.99,
      "Stock": 70,
      "Location": "Aisle 1, Shelf 2"
    },
    {
      "Product Name": "Electric Grill",
      "Description":
          "Indoor electric grill with non-stick surface and adjustable temperature.",
      "Category": "Appliances",
      "Brand": "George Foreman",
      "Price": 139.99,
      "Stock": 40,
      "Location": "Aisle 2, Shelf 3"
    },
    {
      "Product Name": "Cooking Thermometer",
      "Description": "Digital cooking thermometer with quick-read feature.",
      "Category": "Kitchen",
      "Brand": "ThermoWorks",
      "Price": 59.99,
      "Stock": 90,
      "Location": "Aisle 1, Shelf 1"
    },
    {
      "Product Name": "Cotton Towels",
      "Description": "Set of 6 absorbent cotton bath towels in various colors.",
      "Category": "Home",
      "Brand": "Charter Club",
      "Price": 49.99,
      "Stock": 150,
      "Location": "Aisle 2, Shelf 2"
    },
    {
      "Product Name": "Portable Charger",
      "Description":
          "High-capacity portable charger with fast charging capabilities.",
      "Category": "Electronics",
      "Brand": "Anker",
      "Price": 39.99,
      "Stock": 100,
      "Location": "Aisle 1, Shelf 3"
    },
    {
      "Product Name": "Garden Tools Set",
      "Description":
          "Complete set of garden tools including trowel, pruners, and gloves.",
      "Category": "Outdoor",
      "Brand": "Fiskars",
      "Price": 89.99,
      "Stock": 45,
      "Location": "Aisle 2, Shelf 1"
    },
    {
      "Product Name": "Bed Sheets",
      "Description":
          "High-quality bed sheets set with deep pockets and breathable fabric.",
      "Category": "Home",
      "Brand": "Brooklinen",
      "Price": 149.99,
      "Stock": 60,
      "Location": "Aisle 1, Shelf 2"
    },
    {
      "Product Name": "Waffle Maker",
      "Description":
          "Electric waffle maker with non-stick plates and adjustable browning control.",
      "Category": "Appliances",
      "Brand": "Cuisinart",
      "Price": 69.99,
      "Stock": 70,
      "Location": "Aisle 2, Shelf 3"
    },
    {
      "Product Name": "Smart Thermostat",
      "Description":
          "Smart thermostat with Wi-Fi connectivity and energy-saving features.",
      "Category": "Home",
      "Brand": "Nest",
      "Price": 249.99,
      "Stock": 25,
      "Location": "Aisle 1, Shelf 1"
    },
    {
      "Product Name": "Sunglasses",
      "Description":
          "Stylish sunglasses with UV protection and polarized lenses.",
      "Category": "Accessories",
      "Brand": "Ray-Ban",
      "Price": 149.00,
      "Stock": 110,
      "Location": "Aisle 1, Shelf 2"
    },
    {
      "Product Name": "Guitar",
      "Description": "Acoustic guitar with a rich sound and comfortable neck.",
      "Category": "Musical Instruments",
      "Brand": "Yamaha",
      "Price": 299.99,
      "Stock": 15,
      "Location": "Aisle 2, Shelf 1"
    },
    {
      "Product Name": "Kitchen Scale",
      "Description":
          "Digital kitchen scale with precise measurement capabilities.",
      "Category": "Kitchen",
      "Brand": "Ozeri",
      "Price": 29.99,
      "Stock": 80,
      "Location": "Aisle 1, Shelf 3"
    },
    {
      "Product Name": "Electric Heater",
      "Description":
          "Portable electric heater with adjustable settings and safety features.",
      "Category": "Home",
      "Brand": "DeLonghi",
      "Price": 119.99,
      "Stock": 30,
      "Location": "Aisle 2, Shelf 2"
    },
    {
      "Product Name": "Running Shorts",
      "Description": "Breathable running shorts with moisture-wicking fabric.",
      "Category": "Clothing",
      "Brand": "Under Armour",
      "Price": 34.99,
      "Stock": 150,
      "Location": "Aisle 1, Shelf 3"
    },
    {
      "Product Name": "Coffee Maker",
      "Description":
          "Drip coffee maker with programmable settings and auto shut-off.",
      "Category": "Appliances",
      "Brand": "Keurig",
      "Price": 89.99,
      "Stock": 65,
      "Location": "Aisle 2, Shelf 1"
    },
    {
      "Product Name": "Digital Watch",
      "Description":
          "Water-resistant digital watch with multiple functions and backlight.",
      "Category": "Accessories",
      "Brand": "Casio",
      "Price": 49.99,
      "Stock": 95,
      "Location": "Aisle 1, Shelf 2"
    },
    {
      "Product Name": "Smart Light Bulbs",
      "Description":
          "Pack of smart light bulbs with adjustable color temperature and brightness.",
      "Category": "Home",
      "Brand": "Philips Hue",
      "Price": 79.99,
      "Stock": 90,
      "Location": "Aisle 2, Shelf 3"
    },
    {
      "Product Name": "Nutritional Supplements",
      "Description":
          "Daily nutritional supplements with essential vitamins and minerals.",
      "Category": "Health",
      "Brand": "Nature Made",
      "Price": 24.99,
      "Stock": 200,
      "Location": "Aisle 1, Shelf 1"
    },
    {
      "Product Name": "Outdoor Grill",
      "Description":
          "Gas-powered outdoor grill with multiple burners and grilling area.",
      "Category": "Outdoor",
      "Brand": "Weber",
      "Price": 399.99,
      "Stock": 25,
      "Location": "Aisle 2, Shelf 2"
    },
    {
      "Product Name": "Electric Toothbrush",
      "Description":
          "Rechargeable electric toothbrush with multiple brushing modes.",
      "Category": "Health",
      "Brand": "Oral-B",
      "Price": 119.99,
      "Stock": 70,
      "Location": "Aisle 1, Shelf 3"
    }
  ];

  Future<void> uploadProducts() async {
    final databaseReference = FirebaseDatabase.instance.ref().child("products");

    try {
      for (var product in products) {
        // Generate a unique key for each product
        final productName = product["Product Name"];
        final brand = product["Brand"];
        final uniqueKey = _generateUniqueKey(productName, brand);

        if (uniqueKey != null) {
          await databaseReference.child(uniqueKey).set(product);
        }
      }

      print("Products uploaded to Firebase successfully.");
    } catch (e) {
      print("Error uploading products to Firebase: $e");
    }
  }
  //End of dummy data
  */
  Future<void> _submitForm() async {
    //upload dummy data comment below validation before uploading dummy
    // uploadProducts();

    if (_formKey.currentState!.validate()) {
      // Gather form data
      final productName = _productNameController.text;
      final description = _descriptionController.text;
      final category = _categoryController.text;
      final brand = _brandController.text;
      final price = double.tryParse(_priceController.text) ?? 0.0;
      final stock = int.tryParse(_stockController.text) ?? 0;
      final location = _selectedLocation ?? _locationController.text;

      // You can now use these values to save the product to your database
      try {
        // Generate unique key for Firebase
        final uniqueKey = _generateUniqueKey(productName, brand);

        // Save the product to the database
        await _saveProductToDatabase(
          key: uniqueKey,
          productName: productName,
          description: description,
          category: category,
          brand: brand,
          price: price,
          stock: stock,
          location: location,
        );

        // For now, show a snackbar to indicate submission
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product $productName added successfully!')),
        );

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Added to Database'),
              content: SingleChildScrollView(
                child: Text('Product $uniqueKey added successfully!'),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );

        // Clear form
        _formKey.currentState!.reset();
        _productNameController.clear();
        _descriptionController.clear();
        _categoryController.clear();
        _brandController.clear();
        _priceController.clear();
        _stockController.clear();
        setState(() {
          _selectedLocation = null;
        });
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving product: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _productNameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the product name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(labelText: 'Brand'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the brand';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the category';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the stock quantity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                hint: const Text('Select Location'),
                items: _locations.map((location) {
                  return DropdownMenuItem(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLocation = value;
                  });
                },
                validator: (value) {
                  if (value == null && _locationController.text.isEmpty) {
                    return 'Please select or enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Add Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
