import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_project/models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;


  Future<void> saveUserToFirestore(UserModel user) async {
    try {
      await _db.collection('users').doc(user.userId).set(user.toMap());
      print('User saved successfully!');
    } catch (e) {
      print('Error saving user: $e');
    }
  }


  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(userId).get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }


  Future<void> updateUser(UserModel user) async {
    try {
      await _db.collection('users').doc(user.userId).update(user.toMap());
      print('User updated successfully!');
    } catch (e) {
      print('Error updating user: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _db.collection('users').doc(userId).delete();
      print('User deleted successfully!');
    } catch (e) {
      print('Error deleting user: $e');
    }
  }
}
