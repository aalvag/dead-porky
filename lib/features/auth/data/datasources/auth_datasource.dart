import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:dead_porky/features/auth/domain/entities/user.dart';

/// Abstract datasource for authentication operations
abstract class AuthDatasource {
  Future<User> signInWithEmail(String email, String password);
  Future<User> signUpWithEmail(
    String email,
    String password,
    String displayName,
  );
  Future<User> signInWithGoogle();
  Future<User> signInWithApple();
  Future<void> signOut();
  Future<User?> getCurrentUser();
  Future<void> resetPassword(String email);
  Future<void> updateProfile(User user);
  Future<void> deleteAccount();
  Stream<User?> authStateChanges();
}

/// Firebase implementation of AuthDatasource
class FirebaseAuthDatasource implements AuthDatasource {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseAuthDatasource({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<User> signInWithEmail(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _mapFirebaseUser(credential.user!);
  }

  @override
  Future<User> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Update display name
    await credential.user!.updateDisplayName(displayName);

    // Create user document in Firestore
    final user = _mapFirebaseUser(credential.user!, displayName: displayName);
    await _createUserDocument(user);

    return user;
  }

  @override
  Future<User> signInWithGoogle() async {
    // TODO: Implement Google Sign-In
    // final googleUser = await GoogleSignIn().signIn();
    // final googleAuth = await googleUser?.authentication;
    // final credential = firebase_auth.GoogleAuthProvider.credential(
    //   accessToken: googleAuth?.accessToken,
    //   idToken: googleAuth?.idToken,
    // );
    // final result = await _firebaseAuth.signInWithCredential(credential);
    // return _mapFirebaseUser(result.user!);
    throw UnimplementedError('Google Sign-In pendiente de configurar');
  }

  @override
  Future<User> signInWithApple() async {
    // TODO: Implement Apple Sign-In
    // final appleProvider = firebase_auth.AppleAuthProvider();
    // final result = await _firebaseAuth.signInWithProvider(appleProvider);
    // return _mapFirebaseUser(result.user!);
    throw UnimplementedError('Apple Sign-In pendiente de configurar');
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<User?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    return _mapFirebaseUser(firebaseUser);
  }

  @override
  Future<void> resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> updateProfile(User user) async {
    // Update Firebase Auth profile
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      await firebaseUser.updateDisplayName(user.displayName);
      if (user.avatarUrl != null) {
        await firebaseUser.updatePhotoURL(user.avatarUrl);
      }
    }

    // Update Firestore document
    await _firestore.collection('users').doc(user.id).update(user.toJson());
  }

  @override
  Future<void> deleteAccount() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      // Delete user data from Firestore
      await _firestore.collection('users').doc(firebaseUser.uid).delete();
      // Delete Firebase Auth account
      await firebaseUser.delete();
    }
  }

  @override
  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) return null;
      return _mapFirebaseUser(firebaseUser);
    });
  }

  // ==================== Private Helpers ====================

  User _mapFirebaseUser(
    firebase_auth.User firebaseUser, {
    String? displayName,
  }) {
    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: displayName ?? firebaseUser.displayName ?? '',
      avatarUrl: firebaseUser.photoURL,
      phoneNumber: firebaseUser.phoneNumber,
      createdAt: firebaseUser.metadata.creationTime,
      lastLoginAt: firebaseUser.metadata.lastSignInTime,
    );
  }

  Future<void> _createUserDocument(User user) async {
    await _firestore.collection('users').doc(user.id).set({
      'id': user.id,
      'email': user.email,
      'displayName': user.displayName,
      'avatarUrl': user.avatarUrl,
      'phoneNumber': user.phoneNumber,
      'profile': const UserProfile().toJson(),
      'settings': const UserSettings().toJson(),
      'stats': const UserStats().toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
