import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class Ingredient {
  
  final String ingredientId; 
  final String ingredientsName; 
  final String category; 
  final String storage; 
  final double quantity;
  final double minQuantity;
  final String unit;
  final DateTime expirationDate; 
  final String source; 
  final String imageUrl;
 final bool? isThrowed; 

  final String status; 
  final double price; 
  final DateTime? purchaseDate; 
  final DateTime? updateDate; 
  final double quantityAdded;
  final DateTime? addedDate; 
  final Map<String, bool> allergenInfo;
  final String userId;
  final List<dynamic> usageHistory;
  final double kcal;
 
  
  bool isSelected;

  static List<Ingredient> ingredientList = []; 

  Ingredient({
    required this.userId,
    required this.ingredientId,
    required this.ingredientsName,
    required this.category,
    required this.storage,
    required this.quantity,
    required this.minQuantity,
    required this.unit,
    this.status = 'active',
    this.price = 0.0,
    required this.expirationDate,
    this.purchaseDate,
    this.updateDate,
    this.allergenInfo = const {},
    this.quantityAdded = 1.0, 
    this.addedDate,
    required this.source,
    required this.imageUrl,
    this.isSelected = false,
    this.usageHistory = const [],
    this.isThrowed,
    required this.kcal,
  });

  bool isThrownAway() {
    return isThrowed ?? false; 
  }
  

  factory Ingredient.fromAPI({
    required String id,
    required String name,
    required double amount,
    required String unit,
  }) {
     return Ingredient(
      userId: '',              
      ingredientId: id,
      ingredientsName: name,
      category: '',
      storage: '',
      quantity: amount,
      minQuantity: 0,
      unit: unit,
      expirationDate: DateTime.now().add(const Duration(days: 7)),
      source: 'API',
      imageUrl: '',
       kcal: 0.0,
    );
  }

  // ฟังก์ชันแปลงข้อมูลจาก Map (ที่ได้จาก Firebase) ให้เป็น Ingredient object
  factory Ingredient.fromMap(Map<String, dynamic> doc) {
    return Ingredient(
      userId: doc['userId'] ?? '',
      ingredientId: doc['ingredientId'] ?? '',
      ingredientsName: doc['ingredientsName'] ?? 'Unknown',
      category: doc['category'] ?? 'Unknown',
      storage: doc['storage'] ?? 'Unknown',
      quantity: (doc['quantity'] is int)
          ? (doc['quantity'] as int).toDouble()
          : (doc['quantity'] as num?)?.toDouble() ?? 0.0,
      minQuantity: (doc['minQuantity'] is int)
          ? (doc['minQuantity'] as int).toDouble()
          : (doc['minQuantity'] as num?)?.toDouble() ?? 0.0,
      unit: doc['unit'] ?? 'Kilograms (kg)',
      status: doc['status'] ?? 'Unknown',
       price: (doc['price'] is int) ? (doc['price'] as int).toDouble() : doc['price'] ?? 0.0,
      expirationDate: _parseDate(doc['expirationDate']),
      purchaseDate: _parseDate(doc['purchaseDate']),
      updateDate: _parseDate(doc['updateDate']),
      source: doc['source'] ?? 'Home',
      allergenInfo: (doc['allergenInfo'] is Map<String, dynamic>)
          ? Map<String, bool>.from(doc['allergenInfo'])
          : {},
      imageUrl: doc['imageUrl'] ?? '',
      quantityAdded: doc['quantityAdded'] ?? 0,
      addedDate: _parseDate(doc['addedDate']),
      isSelected: doc['isSelected'] ?? false,
      kcal: (doc['kcal'] is int) 
        ? (doc['kcal'] as int).toDouble() 
        : (doc['kcal'] as num?)?.toDouble() ?? 0.0,
        isThrowed: doc['isThrowed'] as bool?, 
    usageHistory: doc['usageHistory'] is List 
        ? List<dynamic>.from(doc['usageHistory'])
        : [],
    );
  }

  // ฟังก์ชันแปลงข้อมูลเป็น Map (เพื่อส่งไป Firebase)
 Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'ingredientId': ingredientId,
      'ingredientsName': ingredientsName,
      'category': category,
      'storage': storage,
      'quantity': quantity,
      'minQuantity': minQuantity,
      'unit': unit,
      'status': status,
      'price': price,
      'expirationDate': expirationDate.toIso8601String(),
      'purchaseDate': purchaseDate?.toIso8601String(),  
      'updateDate': updateDate?.toIso8601String(),      
      'source': source,
      'allergenInfo': allergenInfo,
      'imageUrl': imageUrl,
      'quantityAdded': quantityAdded,
      'addedDate': addedDate?.toIso8601String(),      
      'isSelected': isSelected,
       'kcal': kcal,
       'isThrowed': isThrowed, 
    'usageHistory': usageHistory, 
    };
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {

      String imageUrl = json['imageUrl'] ?? '';

       if (imageUrl.isNotEmpty && !imageUrl.startsWith('http') && !imageUrl.startsWith('assets/')) {
    imageUrl = 'https://firebasestorage.googleapis.com/v0/b/food-management-1ee0f.firebasestorage.app/o/ingredients%2F${Uri.encodeComponent(imageUrl)}?alt=media';
  }
  
  // เพิ่ม print เพื่อตรวจสอบค่าที่เข้ามา
  print("📸 Ingredient JSON: ${json['ingredientsName']} - Image: $imageUrl");
  return Ingredient(
    ingredientId: json['ingredientId'] ?? '',
    ingredientsName: json['ingredientsName'] ?? '',
    category: json['category'] ?? '',
    storage: json['storage'] ?? '',
   quantity: (json['quantity'] is int)
          ? (json['quantity'] as int).toDouble()
          : (json['quantity'] as num?)?.toDouble() ?? 0.0,
      minQuantity: (json['minQuantity'] is int)
          ? (json['minQuantity'] as int).toDouble()
          : (json['minQuantity'] as num?)?.toDouble() ?? 0.0,
    unit: json['unit'] ?? '',
    expirationDate: _parseDate(json['expirationDate']),
    price: (json['price'] ?? 0.0).toDouble(),
    purchaseDate: _parseDate(json['purchaseDate']),
    updateDate: _parseDate(json['updateDate']),
    source: json['source'] ?? '',
    imageUrl: imageUrl,
    isThrowed: json['isThrowed'] as bool?,
    status: json['status'] ?? '',
     quantityAdded: (json['quantityAdded'] is int)
          ? (json['quantityAdded'] as int).toDouble()
          : (json['quantityAdded'] as num?)?.toDouble() ?? 0.0,
    addedDate: _parseDate(json['addedDate']),
    allergenInfo: json['allergenInfo'] is Map
        ? Map<String, bool>.from(json['allergenInfo'])
        : {},  // หากเป็น List หรือค่าผิดประเภท ให้กำหนดค่าเป็น Map ว่าง
    userId: json['userId'] ?? '',
    usageHistory: json['usageHistory'] is List
        ? List<Map<String, dynamic>>.from(json['usageHistory'])
        : [],
     kcal: (json['kcal'] ?? 0.0).toDouble(),
  );
}




  // ✅ ฟังก์ชันแปลง Ingredient -> JSON
 Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'ingredientId': ingredientId,
      'ingredientsName': ingredientsName,
      'category': category,
      'storage': storage,
      'quantity': quantity,
      'minQuantity': minQuantity,
      'unit': unit,
      'status': status,
      'price': price,
      'expirationDate': expirationDate.toIso8601String(),
      'purchaseDate': purchaseDate?.toIso8601String(), 
      'updateDate': updateDate?.toIso8601String(),      
      'source': source,
      'allergenInfo': allergenInfo,
      'imageUrl': imageUrl,
      'quantityAdded': quantityAdded,
      'addedDate': addedDate?.toIso8601String(),      
      'isSelected': isSelected,
       'isThrowed': isThrowed,
        'kcal': kcal,
    };
  }

  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now().add(const Duration(days: 7));
    if (date is String) {
      return DateTime.tryParse(date) ?? DateTime.now().add(const Duration(days: 7));
    }
    if (date is Timestamp) return date.toDate();
    return DateTime.now().add(const Duration(days: 7));
  }

 String getImageUrl() {
  if (imageUrl.isEmpty) {
    return 'assets/images/default_ing.png';
  } else if (imageUrl.startsWith('http')) {
    return imageUrl;
  } else if (imageUrl.startsWith('assets/')) {
    return imageUrl;
  } else {
    // ตรวจสอบรูปแบบชื่อไฟล์และแก้ไขถ้าจำเป็น
    String fileName = imageUrl.trim();
    
    if (!fileName.toLowerCase().endsWith('.png') && 
        !fileName.toLowerCase().endsWith('.jpg') && 
        !fileName.toLowerCase().endsWith('.jpeg')) {
      fileName = '$fileName.png';
    }
    
    String storagePath = fileName.startsWith('ingredients/') ? fileName : 'ingredients/$fileName';
    return 'https://firebasestorage.googleapis.com/v0/b/food-management-1ee0f.appspot.com/o/${Uri.encodeComponent(storagePath)}?alt=media';
  }
}




}