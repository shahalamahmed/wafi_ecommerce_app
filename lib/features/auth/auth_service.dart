import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wafi_ecommerce_app/core/storage/local_storage.dart';
import 'package:wafi_ecommerce_app/core/storage/secure_storage.dart';

import 'auth_model.dart';

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
    SecureStorage? secureStorage,
    LocalStorage? localStorage,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _secureStorage = secureStorage ?? SecureStorage(),
        _localStorage = localStorage ?? LocalStorage();

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  final SecureStorage _secureStorage;
  final LocalStorage _localStorage;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  Future<AppUser?> getCurrentUserProfile() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    await _persistSession(firebaseUser);
    return _fetchOrCreateUserProfile(firebaseUser);
  }

  Future<AppUser> signIn(LoginCredentials credentials) async {
    final result = await _firebaseAuth.signInWithEmailAndPassword(
      email: credentials.email.trim(),
      password: credentials.password,
    );

    final firebaseUser = result.user!;
    await _persistSession(firebaseUser);
    await _mergeAnonymousCart(firebaseUser.uid);
    return _fetchOrCreateUserProfile(firebaseUser);
  }

  Future<AppUser> register(RegistrationData data) async {
    final result = await _firebaseAuth.createUserWithEmailAndPassword(
      email: data.email.trim(),
      password: data.password,
    );

    final firebaseUser = result.user!;
    await firebaseUser.updateDisplayName('${data.firstName} ${data.lastName}'.trim());
    await _upsertUserProfile(
      uid: firebaseUser.uid,
      email: data.email.trim(),
      firstName: data.firstName,
      lastName: data.lastName,
      phone: data.phone,
      role: UserRole.customer,
      isShopOwner: false,
      shopName: '',
    );

    await _persistSession(firebaseUser);
    await _mergeAnonymousCart(firebaseUser.uid);
    return _fetchOrCreateUserProfile(firebaseUser);
  }

  Future<AppUser> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-cancelled',
        message: 'Google sign in was cancelled.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final result = await _firebaseAuth.signInWithCredential(credential);
    final firebaseUser = result.user!;

    final names = _splitDisplayName(firebaseUser.displayName);
    await _upsertUserProfile(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? googleUser.email,
      firstName: names.firstName,
      lastName: names.lastName,
      phone: firebaseUser.phoneNumber ?? '',
      role: UserRole.customer,
      isShopOwner: false,
      shopName: '',
      profilePicture: firebaseUser.photoURL ?? '',
    );

    await _persistSession(firebaseUser);
    await _mergeAnonymousCart(firebaseUser.uid);
    return _fetchOrCreateUserProfile(firebaseUser);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut().catchError((_) {});
    await _firebaseAuth.signOut();
    await _secureStorage.clearAll();
  }

  Future<void> continueAsGuest() async {
    await _secureStorage.clearAll();
  }

  Future<AppUser> _fetchOrCreateUserProfile(User firebaseUser) async {
    final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
    if (doc.exists && doc.data() != null) {
      return AppUser.fromMap(doc.id, doc.data()!);
    }

    final names = _splitDisplayName(firebaseUser.displayName);
    await _upsertUserProfile(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      firstName: names.firstName,
      lastName: names.lastName,
      phone: firebaseUser.phoneNumber ?? '',
      role: UserRole.customer,
      isShopOwner: false,
      shopName: '',
      profilePicture: firebaseUser.photoURL ?? '',
    );

    final createdDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
    return AppUser.fromMap(createdDoc.id, createdDoc.data() ?? <String, dynamic>{});
  }

  Future<void> _upsertUserProfile({
    required String uid,
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required UserRole role,
    required bool isShopOwner,
    required String shopName,
    String profilePicture = '',
  }) async {
    final userRef = _firestore.collection('users').doc(uid);
    final existing = await userRef.get();

    final payload = AppUser(
      uid: uid,
      email: email,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      profilePicture: profilePicture,
      role: role,
      isShopOwner: isShopOwner,
      shopName: shopName,
      createdAt: existing.data()?['createdAt'] is Timestamp
          ? (existing.data()!['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: DateTime.now(),
    ).toMap();

    await userRef.set(payload, SetOptions(merge: true));
  }

  Future<void> _persistSession(User firebaseUser) async {
    final token = await firebaseUser.getIdToken() ?? '';
    await _secureStorage.saveToken(token);
    await _secureStorage.saveUserId(firebaseUser.uid);
  }

  Future<void> _mergeAnonymousCart(String userId) async {
    final anonymousItems = await _localStorage.getAnonymousCart();
    if (anonymousItems.isEmpty) return;

    final cartRef = _firestore.collection('carts').doc(userId);
    final cartDoc = await cartRef.get();

    final existingItems = (cartDoc.data()?['items'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    final mergedItems = <String, Map<String, dynamic>>{};

    for (final item in existingItems) {
      final productId = item['productId'] as String?;
      if (productId == null || productId.isEmpty) continue;
      mergedItems[productId] = Map<String, dynamic>.from(item);
    }

    for (final item in anonymousItems) {
      final productId = item['productId'] as String?;
      if (productId == null || productId.isEmpty) continue;

      final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
      final price = (item['price'] as num?)?.toDouble() ?? 0;
      final current = mergedItems[productId];

      if (current == null) {
        mergedItems[productId] = {
          ...item,
          'id': (item['id'] as String?)?.trim().isNotEmpty == true
              ? (item['id'] as String).trim()
              : productId,
          'productId': productId,
          'quantity': quantity,
          'price': price,
          'subtotal': quantity * price,
        };
      } else {
        final mergedQuantity = ((current['quantity'] as num?)?.toInt() ?? 0) + quantity;
        final currentPrice = (current['price'] as num?)?.toDouble() ?? price;
        mergedItems[productId] = {
          ...current,
          'quantity': mergedQuantity,
          'price': currentPrice,
          'subtotal': mergedQuantity * currentPrice,
        };
      }
    }

    final items = mergedItems.values.toList();
    final subtotal = items.fold<double>(
      0,
      (sum, item) => sum + ((item['subtotal'] as num?)?.toDouble() ?? 0),
    );
    final tax = double.parse((subtotal * 0.05).toStringAsFixed(2));
    final total = subtotal + tax;

    await cartRef.set({
      'userId': userId,
      'items': items,
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _localStorage.clearAnonymousCart();
  }

  _DisplayNameParts _splitDisplayName(String? displayName) {
    final value = (displayName ?? '').trim();
    if (value.isEmpty) return const _DisplayNameParts();

    final parts = value.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return _DisplayNameParts(firstName: parts.first);
    }
    return _DisplayNameParts(
      firstName: parts.first,
      lastName: parts.sublist(1).join(' '),
    );
  }
}

class _DisplayNameParts {
  const _DisplayNameParts({
    this.firstName = '',
    this.lastName = '',
  });

  final String firstName;
  final String lastName;
}
