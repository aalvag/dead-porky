import 'package:dead_porky/features/auth/domain/entities/user.dart';
import 'package:dead_porky/features/auth/domain/repositories/auth_repository.dart';
import 'package:dead_porky/features/auth/data/datasources/auth_datasource.dart';

/// Implementation of AuthRepository using Firebase
class AuthRepositoryImpl implements AuthRepository {
  final AuthDatasource _datasource;

  AuthRepositoryImpl({required AuthDatasource datasource})
    : _datasource = datasource;

  @override
  Future<User> signInWithEmail(String email, String password) {
    return _datasource.signInWithEmail(email, password);
  }

  @override
  Future<User> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) {
    return _datasource.signUpWithEmail(email, password, displayName);
  }

  @override
  Future<User> signInWithGoogle() {
    return _datasource.signInWithGoogle();
  }

  @override
  Future<User> signInWithApple() {
    return _datasource.signInWithApple();
  }

  @override
  Future<void> signOut() {
    return _datasource.signOut();
  }

  @override
  Future<User?> getCurrentUser() {
    return _datasource.getCurrentUser();
  }

  @override
  Future<void> resetPassword(String email) {
    return _datasource.resetPassword(email);
  }

  @override
  Future<void> updateProfile(User user) {
    return _datasource.updateProfile(user);
  }

  @override
  Future<void> deleteAccount() {
    return _datasource.deleteAccount();
  }

  @override
  Stream<User?> authStateChanges() {
    return _datasource.authStateChanges();
  }
}
