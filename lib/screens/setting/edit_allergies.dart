import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class EditAllergies extends StatefulWidget {
  @override
  _EditAllergiesState createState() => _EditAllergiesState();
}

class _EditAllergiesState extends State<EditAllergies> {
  final List<Map<String, String>> foodAllergies = [
    {'name': 'Milk', 'image': 'assets/images/allergies_milk.jpg'},
    {'name': 'Eggs', 'image': 'assets/images/allergies_egg.jpg'},
    {'name': 'Peanuts', 'image': 'assets/images/allergies_peanuts.jpg'},
    {'name': 'Wheat', 'image': 'assets/images/allergies_wheat.jpg'},
    {'name': 'Soybeans', 'image': 'assets/images/allergies_soybeans.jpg'},
    {'name': 'Shrimp', 'image': 'assets/images/allergies_shrimp.jpg'},
    {'name': 'Crab', 'image': 'assets/images/allergies_crab.jpg'},
    {'name': 'Squid', 'image': 'assets/images/allergies_squid.jpg'},
    {'name': 'Oyster', 'image': 'assets/images/allergies_oyster.jpg'},
    {'name': 'Corn', 'image': 'assets/images/allergies_corn.jpg'},
    {'name': 'Gluten', 'image': 'assets/images/allergies_gluten.jpg'},
    {'name': 'Alcohol', 'image': 'assets/images/allergies_alcohol.jpg'},
  ];

  final List<String> selectedAEditAllergies = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadExistingAllergies();
  }
  
  Future<void> _loadExistingAllergies() async {
    setState(() {
      _isLoading = true;
    });
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final allergiesSnapshot = await FirebaseFirestore.instance
            .collection('userAllergies')
            .doc(user.uid)
            .collection('Allergies')
            .get();
        
        setState(() {
          selectedAEditAllergies.clear();
        });
        
        for (var doc in allergiesSnapshot.docs) {
          Map<String, dynamic> data = doc.data();
          if (data.containsKey('foodName')) {
            setState(() {
              selectedAEditAllergies.add(data['foodName']);
            });
          }
        }
        
        print('✅ Existing allergies loaded: ${selectedAEditAllergies.join(", ")}');
      } catch (e) {
        print('❌ Error loading allergies: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      print('⚠️ User not logged in');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> saveAllergies(String userId, List<String> selectedAllergies) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final allergiesRef = FirebaseFirestore.instance
          .collection('userAllergies')
          .doc(userId)
          .collection('Allergies');

      final existingAllergiesSnapshot = await allergiesRef.get();
      for (var doc in existingAllergiesSnapshot.docs) {
        await doc.reference.delete();
      }

      for (var food in selectedAllergies) {
        await allergiesRef.add({
          'foodName': food,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      print('✅ Food allergies saved successfully: ${selectedAllergies.join(", ")}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Food allergies updated successfully!'),
          backgroundColor: Color(0xFF325b51),
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      print('❌ Error saving food allergies: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update allergies: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading && selectedAEditAllergies.isEmpty
        ? Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF325b51)),
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.only(top: 30, left: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const FaIcon(FontAwesomeIcons.arrowLeft),
                      color: Colors.black,
                      iconSize: 20,
                    ),
                    const Text(
                      'Edit Food Allergies',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 40),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Do you have any allergies ?',
                        style: TextStyle(
                          fontSize: 25,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: foodAllergies.length,
                        itemBuilder: (context, index) {
                          final food = foodAllergies[index];
                          final isSelected = selectedAEditAllergies.contains(food['name']);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedAEditAllergies.remove(food['name']);
                                } else {
                                  selectedAEditAllergies.add(food['name']!);
                                }
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF78d454) : Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                                      child: Image.asset(
                                        food['image']!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      food['name']!,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: _isLoading 
                            ? null 
                            : () async {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  String userId = user.uid;
                                  await saveAllergies(userId, selectedAEditAllergies.toList());
                                } else {
                                  print("⚠️ User not logged in");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('You must be logged in to save allergies'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF325b51),
                            minimumSize: const Size(50, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 80),
                          ),
                          child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Update Food Allergies',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }
}