import 'package:cloud_firestore/cloud_firestore.dart';

class Ingredient {
  final String userId; // userId ของผู้ใช้
  final String ingredientId; // รหัสวัตถุดิบ
  final String ingredientsName; // ชื่อวัตถุดิบ
  final String category; // หมวดหมู่วัตถุดิบ
  final String storage; // วิธีการเก็บรักษา
  final int quantity; // ปริมาณ
  final int minQuantity; // ปริมาณขั้นต่ำ
  final String unit;
  final String status; // สถานะ (เช่น วัตถุดิบที่หมดอายุ, ปกติ)
  final double price; // ราคา
  final DateTime expirationDate; // วันหมดอายุ
  final DateTime purchaseDate; // วันซื้อ
  final DateTime updateDate; // วันที่อัปเดตล่าสุด
  final String source; // แหล่งที่มาจากหน้า Cart
  final int quantityAdded;
  final DateTime addedDate;
  final Map<String, bool> allergenInfo;
  final String imageUrl;
  bool isSelected;

  static List<Ingredient> ingredientList = []; // ข้อมูลสารก่อภูมิแพ้

  Ingredient({
    required this.userId,
    required this.ingredientId,
    required this.ingredientsName,
    required this.category,
    required this.storage,
    required this.quantity,
    required this.minQuantity,
    required this.unit,
    required this.status,
    required this.price,
    required this.expirationDate,
    required this.purchaseDate,
    required this.updateDate,
    required this.source,
    required this.allergenInfo,
    required this.imageUrl,
    required this.quantityAdded,
    required this.addedDate,
    this.isSelected = false,
  });

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
      price: doc['price'] ?? 0.0,
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
      'purchaseDate': purchaseDate.toIso8601String(),
      'updateDate': updateDate.toIso8601String(),
      'source': source,
      'allergenInfo': allergenInfo,
      'imageUrl': imageUrl,
      'quantityAdded': quantityAdded,
      'addedDate': addedDate.toIso8601String(),
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
      'purchaseDate': purchaseDate.toIso8601String(),
      'updateDate': updateDate.toIso8601String(),
      'source': source,
      'allergenInfo': allergenInfo,
      'imageUrl': imageUrl,
      'quantityAdded': quantityAdded,
      'addedDate' : addedDate.toIso8601String(),
      'isSelected': isSelected,
    };
  }

  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now().add(Duration(days: 7));
    if (date is String)
      return DateTime.tryParse(date) ?? DateTime.now().add(Duration(days: 7));
    if (date is Timestamp) return date.toDate();
    return DateTime.now().add(Duration(days: 7));
  }
}