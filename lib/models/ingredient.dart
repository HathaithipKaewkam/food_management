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
  final DateTime expDate; // วันหมดอายุ
  final DateTime purchaseDate; // วันซื้อ
  final DateTime updateDate; // วันที่อัปเดตล่าสุด
  final String source; // แหล่งที่มาจากหน้า Cart
  final Map<String, bool> allergenInfo;
  final String imageUrl;
  bool isSelected;

  static List<Ingredient> ingredientList = [];// ข้อมูลสารก่อภูมิแพ้

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
    required this.expDate,
    required this.purchaseDate,
    required this.updateDate,
    required this.source,
    required this.allergenInfo,
    required this.imageUrl,
    this.isSelected = false,
  });

  // ฟังก์ชันแปลงข้อมูลจาก Map (ที่ได้จาก Firebase) ให้เป็น Ingredient object
  factory Ingredient.fromMap(Map<String, dynamic> doc) {
    return Ingredient(
        userId: doc['userId'] ?? '',
        ingredientId: doc['ingredientId'] ?? '',
        ingredientsName: doc['ingredientName'] ?? 'Unknown',
        category: doc['category'] ?? 'Unknown',
        storage: doc['storage'] ?? 'Unknown',
        quantity: doc['quantity'] ?? 0,
        minQuantity: doc['minQuantity'] ?? 0,
        unit: doc['unit'] ?? 'Kilograms (kg)',
        status: doc['status'] ?? 'Unknown',
        price: doc['price'] ?? 0.0,
        expDate: doc['expDate'] != null
            ? DateTime.tryParse(doc['expDate']) ?? DateTime.now()
            : DateTime.now(),
        purchaseDate: doc['purchaseDate'] != null
            ? DateTime.tryParse(doc['purchaseDate']) ?? DateTime.now()
            : DateTime.now(),
        updateDate: doc['updateDate'] != null
            ? DateTime.tryParse(doc['updateDate']) ?? DateTime.now()
            : DateTime.now(),
        source: doc['source'] ?? 'Unknown',
        allergenInfo: Map<String, bool>.from(doc['allergenInfo'] ?? {}),
        imageUrl: doc['imageUrl'] ?? '',
        isSelected: doc['isSelected'] ?? false,);
  }


  // ฟังก์ชันแปลงข้อมูลเป็น Map (เพื่อส่งไป Firebase)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'ingredientId': ingredientId,
      'ingredientName': ingredientsName,
      'category': category,
      'storage': storage,
      'quantity': quantity,
      'minQuantity': minQuantity,
      'unit': unit,
      'status': status,
      'price': price,
      'expDate': expDate.toIso8601String(),
      'purchaseDate': purchaseDate.toIso8601String(),
      'updateDate': updateDate.toIso8601String(),
      'source': source,
      'allergenInfo': allergenInfo,
      'imageUrl': imageUrl, 
      'isSelected': isSelected,
    };
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      userId: json['userId'] ?? '',
      ingredientId: json['ingredientId'] ?? '',
      ingredientsName: json['ingredientName'] ?? 'Unknown',
      category: json['category'] ?? 'Unknown',
      storage: json['storage'] ?? 'Unknown',
      quantity: json['quantity'] ?? 0,
      minQuantity: json['minQuantity'] ?? 0,
      unit: json['unit'] ?? 'Kilograms (kg)',
      status: json['status'] ?? 'Unknown',
      price: (json['price'] ?? 0.0).toDouble(),
      expDate: json['expDate'] != null
          ? DateTime.tryParse(json['expDate']) ?? DateTime.now()
          : DateTime.now(),
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.tryParse(json['purchaseDate']) ?? DateTime.now()
          : DateTime.now(),
      updateDate: json['updateDate'] != null
          ? DateTime.tryParse(json['updateDate']) ?? DateTime.now()
          : DateTime.now(),
      source: json['source'] ?? 'Unknown',
      allergenInfo: Map<String, bool>.from(json['allergenInfo'] ?? {}),
      imageUrl: json['imageUrl'] ?? '',
      isSelected: json['isSelected'] ?? false,
    );
  }

  // ✅ ฟังก์ชันแปลง Ingredient -> JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'ingredientId': ingredientId,
      'ingredientName': ingredientsName,
      'category': category,
      'storage': storage,
      'quantity': quantity,
      'minQuantity': minQuantity,
      'unit': unit,
      'status': status,
      'price': price,
      'expDate': expDate.toIso8601String(),
      'purchaseDate': purchaseDate.toIso8601String(),
      'updateDate': updateDate.toIso8601String(),
      'source': source,
      'allergenInfo': allergenInfo,
      'imageUrl': imageUrl,
      'isSelected': isSelected,
    };
  }
}

