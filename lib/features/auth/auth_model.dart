import 'package:cloud_firestore/cloud_firestore.dart';

enum AuthView { login, register }

enum AuthStatus {
  initial,
  loading,
  authenticated,
  anonymous,
  unauthenticated,
  failure,
}

enum UserRole { customer, owner }

class LoginCredentials {
  const LoginCredentials({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}

class RegistrationData {
  const RegistrationData({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.password,
  });

  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String password;
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.profilePicture,
    required this.role,
    required this.isShopOwner,
    required this.shopName,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String profilePicture;
  final UserRole role;
  final bool isShopOwner;
  final String shopName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayName {
    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) return fullName;
    return email;
  }

  bool get isCustomer => role == UserRole.customer;
  bool get isOwner => role == UserRole.owner || isShopOwner;

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'profilePicture': profilePicture,
      'role': role.name,
      'isShopOwner': isShopOwner,
      'shopName': shopName,
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: (map['email'] as String?)?.trim() ?? '',
      firstName: (map['firstName'] as String?)?.trim() ?? '',
      lastName: (map['lastName'] as String?)?.trim() ?? '',
      phone: (map['phone'] as String?)?.trim() ?? '',
      profilePicture: (map['profilePicture'] as String?)?.trim() ?? '',
      role: _parseRole(map['role'] as String?),
      isShopOwner: map['isShopOwner'] as bool? ?? false,
      shopName: (map['shopName'] as String?)?.trim() ?? '',
      createdAt: _readDateTime(map['createdAt']),
      updatedAt: _readDateTime(map['updatedAt']),
    );
  }

  static UserRole _parseRole(String? raw) {
    return raw == UserRole.owner.name ? UserRole.owner : UserRole.customer;
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

class AuthState {
  const AuthState({
    required this.status,
    required this.view,
    this.user,
    this.errorMessage,
  });

  const AuthState.initial()
      : status = AuthStatus.initial,
        view = AuthView.login,
        user = null,
        errorMessage = null;

  final AuthStatus status;
  final AuthView view;
  final AppUser? user;
  final String? errorMessage;

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isAnonymous => status == AuthStatus.anonymous;
  bool get hasError => errorMessage != null && errorMessage!.trim().isNotEmpty;

  AuthState copyWith({
    AuthStatus? status,
    AuthView? view,
    AppUser? user,
    bool clearUser = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      view: view ?? this.view,
      user: clearUser ? null : user ?? this.user,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
