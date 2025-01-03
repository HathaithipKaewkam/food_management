class UserModel {
  String userId;  
  String email;
  String username;
  String password;

  UserModel({
    required this.userId,
    required this.email,
    required this.username,
    required this.password,
  });

  
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'],  
      email: map['email'],
      username: map['username'],
      password: map['password'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'username': username,
      'password': password,
    };
  }
}
