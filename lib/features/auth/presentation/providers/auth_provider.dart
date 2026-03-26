import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dead_porky/features/auth/domain/entities/user.dart';
import 'package:dead_porky/features/auth/domain/repositories/auth_repository.dart';
import 'package:dead_porky/features/auth/data/datasources/auth_datasource.dart';
import 'package:dead_porky/features/auth/data/repositories/auth_repository_impl.dart';

// ==================== Providers ====================

/// Auth datasource provider
final authDatasourceProvider = Provider<AuthDatasource>((ref) {
  return FirebaseAuthDatasource();
});

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final datasource = ref.watch(authDatasourceProvider);
  return AuthRepositoryImpl(datasource: datasource);
});

// ==================== Auth State Notifier ====================

/// Auth state enum
enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

/// Auth state
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({AuthStatus? status, User? user, String? errorMessage}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => status == AuthStatus.error;
}

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  StreamSubscription<User?>? _authSubscription;

  AuthNotifier({required AuthRepository repository})
    : _repository = repository,
      super(const AuthState()) {
    _init();
  }

  void _init() {
    // Listen to auth state changes
    _authSubscription = _repository.authStateChanges().listen(
      (user) {
        if (user != null) {
          state = AuthState(status: AuthStatus.authenticated, user: user);
        } else {
          state = const AuthState(status: AuthStatus.unauthenticated);
        }
      },
      onError: (error) {
        state = AuthState(
          status: AuthStatus.error,
          errorMessage: error.toString(),
        );
      },
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repository.signInWithEmail(email, password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: _parseError(e));
    }
  }

  Future<void> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repository.signUpWithEmail(
        email,
        password,
        displayName,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: _parseError(e));
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repository.signInWithGoogle();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: _parseError(e));
    }
  }

  Future<void> signInWithApple() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repository.signInWithApple();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: _parseError(e));
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.resetPassword(email);
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: _parseError(e));
    }
  }

  void clearError() {
    state = state.copyWith(
      status: state.user != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated,
      errorMessage: null,
    );
  }

  String _parseError(dynamic error) {
    final msg = error.toString();
    if (msg.contains('user-not-found')) {
      return 'No se encontró una cuenta con este correo';
    } else if (msg.contains('wrong-password')) {
      return 'Contraseña incorrecta';
    } else if (msg.contains('email-already-in-use')) {
      return 'Ya existe una cuenta con este correo';
    } else if (msg.contains('weak-password')) {
      return 'La contraseña es muy débil';
    } else if (msg.contains('invalid-email')) {
      return 'Correo electrónico inválido';
    } else if (msg.contains('too-many-requests')) {
      return 'Demasiados intentos. Intenta más tarde';
    } else if (msg.contains('network')) {
      return 'Error de conexión. Verifica tu internet';
    }
    return 'Ha ocurrido un error. Intenta de nuevo';
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

/// Auth notifier provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository: repository);
});

/// Current user provider (convenience)
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authNotifierProvider).user;
});

/// Is authenticated provider (convenience)
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});
