class Ingredient {
  final int ingrediantsId;
  final String ingrediantsName;
  final String category;
  final String unit;
  final int shelfLife; // อายุการเก็บรักษา (วัน)
  final String storage;
  final String imageStorage; // วิธีการเก็บรักษา
  final DateTime expDate; // วันหมดอายุ
  final double price; // ราคา
  final int quantity; // ปริมาณ
  final String source; // แหล่งที่มา
  final String imageUrl; // URL รูปภาพ
  bool isSelected; // สถานะการเลือก

  Ingredient({
    required this.ingrediantsId,
    required this.ingrediantsName,
    required this.category,
    required this.unit,
    required this.shelfLife,
    required this.storage,
    required this.imageStorage,
    required this.expDate,
    required this.price,
    required this.quantity,
    required this.source,
    required this.imageUrl,
    this.isSelected = false, // ค่าเริ่มต้นเป็น false
  });

  // Static list of ingredient data
  static List<Ingredient> ingredientList = [
    Ingredient(
      ingrediantsId: 1,
      ingrediantsName: 'Tomato',
      category: 'Vegetable',
      unit: 'kg',
      shelfLife: 7,
      storage: 'Fridge',
      imageStorage: 'assets/images/fridge_stroage.png',
      expDate: DateTime(2024, 12, 12),
      price: 50.0,
      quantity: 5,
      source: 'Local Farm',
      imageUrl: 'assets/images/tomato.png',
    ),
    Ingredient(
      ingrediantsId: 2,
      ingrediantsName: 'Milk',
      category: 'Dairy',
      unit: 'boxes',
      shelfLife: 7,
      storage: 'Fridge',
      imageStorage: 'assets/images/fridge_stroage.png',
      expDate: DateTime(2024, 11, 30),
      price: 30.0,
      quantity: 2,
      source: 'Local Farm',
      imageUrl: 'assets/images/milk.png',
    ),
    Ingredient(
      ingrediantsId: 3,
      ingrediantsName: 'Noodle',
      category: 'Grains',
      unit: 'pack',
      shelfLife: 365,
      storage: 'Pantry',
      imageStorage: 'assets/images/pantry_stroage.png',
      expDate: DateTime(2025, 6, 15),
      price: 20.0,
      quantity: 10,
      source: 'Local Supplier',
      imageUrl: 'assets/images/noodle.png',
    ),
    Ingredient(
      ingrediantsId: 4,
      ingrediantsName: 'Pork Chops',
      category: 'Meat',
      unit: 'piece',
      shelfLife: 3,
      storage: 'Freezer',
      imageStorage: 'assets/images/freezer_stroage.png',
      expDate: DateTime(2024, 12, 13),
      price: 300.0,
      quantity: 2,
      source: 'Local Farm',
      imageUrl: 'assets/images/pork.png',
    ),
    Ingredient(
      ingrediantsId: 5,
      ingrediantsName: 'Egg',
      category: 'Dairy',
      unit: 'unit',
      shelfLife: 30,
      storage: 'Fridge',
      imageStorage: 'assets/images/fridge_stroage.png',
      expDate: DateTime(2025, 11, 30),
      price: 70.0,
      quantity: 2,
      source: 'Local Farm',
      imageUrl: 'assets/images/egg.png',
    ),
  ];

  // Method for getting selected ingredients
  static List<Ingredient> addedToCartIngredients() {
    return ingredientList.where((element) => element.isSelected).toList();
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      ingrediantsId: json['id'],
      ingrediantsName: json['name'],
      category: json['category'],
      unit: json['unit'],
      shelfLife: json['shelfLife'],
      storage: json['storage'],
      imageStorage:  json['imageUrl'],
      expDate: DateTime.parse(json['expDate']),
      price: json['price'].toDouble(),
      quantity: json['quantity'],
      source: json['source'],
      imageUrl: json['imageUrl'],
      isSelected: json['isSelected'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': ingrediantsId,
      'name': ingrediantsName,
      'category': category,
      'unit': unit,
      'shelfLife': shelfLife,
      'storage': storage,
      'expDate': expDate.toIso8601String(),
      'price': price,
      'quantity': quantity,
      'source': source,
      'imageUrl': imageUrl,
      'isSelected': isSelected,
    };
  }
}

void main() {
  // เรียกใช้งาน static method
  var selectedIngredients = Ingredient.addedToCartIngredients();
  print(selectedIngredients);
}
