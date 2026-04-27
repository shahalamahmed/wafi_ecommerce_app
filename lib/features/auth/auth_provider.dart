import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_model.dart';
import 'auth_service.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._service) : super(const AuthState.initial()) {
    _subscription = _service.authStateChanges().listen(_onAuthChanged);
    bootstrap();
  }

  final AuthService _service;
  late final StreamSubscription<User?> _subscription;

  Future<void> bootstrap() async {
    if (state.isLoading) return;
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final user = await _service.getCurrentUserProfile();
      if (!mounted) return;

      if (user == null) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearError: true,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: error.message ?? error.code,
        clearUser: true,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        status: AuthStatus.failure,
        errorMessage: error.toString(),
        clearUser: true,
      );
    }
  }

  void setView(AuthView view) {
    state = state.copyWith(view: view, clearError: true);
  }

  Future<void> login(LoginCredentials credentials) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final user = await _service.signIn(credentials);
      if (!mounted) return;
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        view: AuthView.login,
        clearError: true,
      );
    } on FirebaseAuthException catch (error) {
      _setFailure(error.message ?? error.code);
    } catch (error) {
      _setFailure(error.toString());
    }
  }

  Future<void> register(RegistrationData data) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final user = await _service.register(data);
      if (!mounted) return;
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        view: AuthView.login,
        clearError: true,
      );
    } on FirebaseAuthException catch (error) {
      _setFailure(error.message ?? error.code);
    } catch (error) {
      _setFailure(error.toString());
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final user = await _service.signInWithGoogle();
      if (!mounted) return;
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        clearError: true,
      );
    } on FirebaseAuthException catch (error) {
      _setFailure(error.message ?? error.code);
    } catch (error) {
      _setFailure(error.toString());
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      await _service.sendPasswordResetEmail(email);
      if (!mounted) return;
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearError: true,
      );
    } on FirebaseAuthException catch (error) {
      _setFailure(error.message ?? error.code);
    } catch (error) {
      _setFailure(error.toString());
    }
  }

  Future<void> continueAsGuest() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      await _service.continueAsGuest();
      if (!mounted) return;
      state = state.copyWith(
        status: AuthStatus.anonymous,
        clearUser: true,
        clearError: true,
      );
    } catch (error) {
      _setFailure(error.toString());
    }
  }

  void exitGuestMode() {
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      clearUser: true,
      clearError: true,
    );
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      await _service.signOut();
      if (!mounted) return;
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        clearError: true,
      );
    } catch (error) {
      _setFailure(error.toString());
    }
  }

  Future<void> refreshProfile() async {
    try {
      final user = await _service.getCurrentUserProfile();
      if (!mounted || user == null) return;
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        clearError: true,
      );
    } catch (_) {
      // Silent refresh for shell profile UI.
    }
  }

  Future<void> updateProfilePhoto(String imagePath) async {
    final currentUser = state.user;
    if (currentUser == null) {
      _setFailure('Sign in first to update your profile picture.');
      return;
    }

    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final user = await _service.updateProfilePhoto(currentUser.uid, imagePath);
      if (!mounted) return;
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        clearError: true,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: currentUser,
        errorMessage: error.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> _onAuthChanged(User? firebaseUser) async {
    if (!mounted) return;

    if (firebaseUser == null) {
      if (state.status != AuthStatus.anonymous) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
          clearError: true,
        );
      }
      return;
    }

    try {
      final user = await _service.getCurrentUserProfile();
      if (!mounted || user == null) return;
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        clearError: true,
      );
    } catch (_) {
      // Listener should not break the foreground flow.
    }
  }

  void _setFailure(String message) {
    if (!mounted) return;
    state = state.copyWith(
      status: AuthStatus.failure,
      errorMessage: message,
      clearUser: true,
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});
