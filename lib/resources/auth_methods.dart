import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:memesworld/models/user.dart' as model;

class AuthMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user details
  Future<model.User> getUserDetails() async {
    User currentUser = _auth.currentUser!;
    DocumentSnapshot documentSnapshot =
    await _firestore.collection('users').doc(currentUser.uid).get();

    return model.User.fromSnap(documentSnapshot);
  }

  // Sign up user
  Future<String> signUpUser({
    required String email,
    required String password,
    required String username,
    required String bio,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty &&
          password.isNotEmpty &&
          username.isNotEmpty &&
          bio.isNotEmpty) {
        // Register user in Firebase Auth
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Default profile picture
        String photoUrl = 'https://i.stack.imgur.com/l60Hf.png';

        // Create user model
        model.User user = model.User(
          username: username,
          uid: cred.user!.uid,
          photoUrl: photoUrl,
          email: email,
          bio: bio,
          followers: [],
          following: [],
        );

        // Add user to Firestore
        await _firestore.collection("users").doc(cred.user!.uid).set(user.toJson());

        res = "success";
      } else {
        res = "Please enter all the fields";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Login user
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
        res = "success";
      } else {
        res = "Please enter all the fields";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Reset password
  Future<String> resetPassword(String email) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty) {
        await _auth.sendPasswordResetEmail(email: email);
        res = "Password reset email sent";
      } else {
        res = "Please enter your email";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  // Sign out user
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
