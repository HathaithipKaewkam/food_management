import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();


  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      print('Error signing up: $e');
      return null;
    }
  }


  Future<User?> signIn(String email, String password) async {
  try {
    UserCredential result = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return result.user;
  } on FirebaseAuthException catch (e) {
    if (e.code == 'invalid-credential') {
      print('Invalid credential: ${e.message}');
    } else if (e.code == 'user-not-found') {
      print('User not found: ${e.message}');
    } else if (e.code == 'wrong-password') {
      print('Wrong password: ${e.message}');
    } else {
      print('Error signing in: ${e.message}');
    }
    rethrow; 
  }
}

 Future<User?> signUpWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;


      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      String username = googleUser.displayName ?? googleUser.email.split('@')[0];
      return userCredential.user;
    } catch (e) {
      print("Error during Google sign-up: $e");
      return null;
    }
  }

  Future<User?> signInWithGoogle() async {
  try {
    await _googleSignIn.signOut();
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      return null; 
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      
      bool isInFirestore = await isUserInFirestore(user.uid);

      if (!isInFirestore) {
       
        await _auth.signOut();
        return null;
      }
    }

    return user;
  } catch (e) {
    print("Error during Google sign-in: $e");
    return null;
  }
}

  Future<bool> isUserInFirestore(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users') 
          .doc(uid)
          .get();

      return userDoc.exists; 
    } catch (e) {
      print('Error checking Firestore: $e');
      return false;
    }
  }


  Future<void> signOut() async {
    await _auth.signOut();
  }
}
