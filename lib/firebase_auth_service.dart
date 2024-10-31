import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUp({required String email, required String password}) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
    // Send verification email
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> signInWithGoogle() async {
    // Implement Google Sign-In logic here
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}