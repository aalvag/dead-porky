import 'package:dead_porky/features/auth/domain/entities/user.dart';

/// Abstract repository for authentication operations
abstract class AuthRepository {
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
