import 'package:cloud_firestore/cloud_firestore.dart';

class Ingredient {
  
  final String ingredientId; 
  final String ingredientsName; 
  final String category; 
  final String storage; 
  final int quantity; 
  final int minQuantity; 
  final String unit;
  final DateTime expirationDate; 
  final String source; 
  final String imageUrl;

  final String status; 
  final double price; 
  final DateTime? purchaseDate; 
  final DateTime? updateDate; 
  final int quantityAdded;
  final DateTime? addedDate; 
  final Map<String, bool> allergenInfo;
  final String userId; 
  
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
    this.quantityAdded = 1, 
    this.addedDate,
    required this.source,
    required this.imageUrl,
    this.isSelected = false,
  });

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
      quantity: amount.round(),
      minQuantity: 0,
      unit: unit,
      expirationDate: DateTime.now().add(const Duration(days: 7)),
      source: 'API',
      imageUrl: '',
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
      quantity: doc['quantity'] ?? 0,
      minQuantity: doc['minQuantity'] ?? 0,
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
    };
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      userId: json['userId'] ?? '',
      ingredientId: json['ingredientId'] ?? '',
      ingredientsName: json['ingredientsName'] ?? 'Unknown',
      category: json['category'] ?? 'Unknown',
      storage: json['storage'] ?? 'Unknown',
      quantity: json['quantity'] ?? 0,
      minQuantity: json['minQuantity'] ?? 0,
      unit: json['unit'] ?? 'Kilograms (kg)',
      status: json['status'] ?? 'Unknown',
      price: (json['price'] ?? 0.0).toDouble(),
      expirationDate: _parseDate(json['expirationDate']),
      purchaseDate: _parseDate(json['purchaseDate']),
      updateDate: _parseDate(json['updateDate']),

      source: json['source'] ?? 'Home',

      // ✅ ตรวจสอบ `allergenInfo`
      allergenInfo: json['allergenInfo'] is Map<String, dynamic>
          ? Map<String, bool>.from(json['allergenInfo'])
          : {},
      imageUrl: json['imageUrl'] ?? '',
      quantityAdded: json['quantityAdded'] ?? 0,
      addedDate: _parseDate(json['addedDate']),

      isSelected: json['isSelected'] ?? false,
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
}