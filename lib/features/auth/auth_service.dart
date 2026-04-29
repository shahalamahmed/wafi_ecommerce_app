import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:wafi_ecommerce_app/core/storage/local_storage.dart';
import 'package:wafi_ecommerce_app/core/storage/secure_storage.dart';
import 'package:wafi_ecommerce_app/firebase_options.dart';

import 'auth_model.dart';

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
    SecureStorage? secureStorage,
    LocalStorage? localStorage,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? _buildGoogleSignIn(),
       _secureStorage = secureStorage ?? SecureStorage(),
       _localStorage = localStorage ?? LocalStorage();

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  final SecureStorage _secureStorage;
  final LocalStorage _localStorage;

  static const String _googleWebClientId =
      '175234345266-t59kfbmanrtnsr5qo9fb1mbo9u17s336.apps.googleusercontent.com';

  static GoogleSignIn _buildGoogleSignIn() {
    if (Platform.isIOS) {
      return GoogleSignIn(
        clientId: DefaultFirebaseOptions.ios.iosClientId,
        serverClientId: _googleWebClientId,
      );
    }

    return GoogleSignIn(serverClientId: _googleWebClientId);
  }

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
    await firebaseUser.updateDisplayName(
      '${data.firstName} ${data.lastName}'.trim(),
    );
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
    await _googleSignIn.signOut().catchError((_) => null);
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-cancelled',
        message: 'Google sign in was cancelled.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if ((accessToken == null || accessToken.isEmpty) &&
        (idToken == null || idToken.isEmpty)) {
      throw FirebaseAuthException(
        code: 'google-sign-in-misconfigured',
        message:
            'Google sign in did not return a valid token. Check the Firebase OAuth client configuration.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: accessToken,
      idToken: idToken,
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
    await _googleSignIn.signOut().catchError((_) => null);
    await _firebaseAuth.signOut();
    await _secureStorage.clearAll();
  }

  Future<void> continueAsGuest() async {
    await _secureStorage.clearAll();
  }

  Future<AppUser> updateProfilePhoto(String userId, String imagePath) async {
    final file = File(imagePath);
    if (!file.existsSync()) {
      throw Exception('Selected image file was not found on device.');
    }

    final savedImagePath = await _saveProfilePhotoLocally(
      userId: userId,
      sourceFile: file,
    );

    await _firestore.collection('users').doc(userId).set({
      'profilePicture': savedImagePath,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null && firebaseUser.uid == userId) {
      await firebaseUser.updatePhotoURL(savedImagePath);
    }

    final doc = await _firestore.collection('users').doc(userId).get();
    return AppUser.fromMap(doc.id, doc.data() ?? <String, dynamic>{});
  }

  Future<String> _saveProfilePhotoLocally({
    required String userId,
    required File sourceFile,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final profileDir = Directory(path.join(appDir.path, 'profile_photos'));
    if (!await profileDir.exists()) {
      await profileDir.create(recursive: true);
    }

    final extension = _normalizedExtension(sourceFile.path);
    final targetPath = path.join(profileDir.path, '$userId.$extension');
    final targetFile = File(targetPath);

    if (await targetFile.exists()) {
      await targetFile.delete();
    }

    final copiedFile = await sourceFile.copy(targetPath);
    return copiedFile.path;
  }

  Future<AppUser> _fetchOrCreateUserProfile(User firebaseUser) async {
    final doc = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();
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

    final createdDoc = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();
    return AppUser.fromMap(
      createdDoc.id,
      createdDoc.data() ?? <String, dynamic>{},
    );
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

    final existingItems =
        (cartDoc.data()?['items'] as List<dynamic>? ?? <dynamic>[])
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
        final mergedQuantity =
            ((current['quantity'] as num?)?.toInt() ?? 0) + quantity;
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
      (runningTotal, item) =>
          runningTotal + ((item['subtotal'] as num?)?.toDouble() ?? 0),
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

  String _normalizedExtension(String imagePath) {
    final lastDot = imagePath.lastIndexOf('.');
    if (lastDot < 0 || lastDot == imagePath.length - 1) {
      return 'jpg';
    }

    final raw = imagePath.substring(lastDot + 1).toLowerCase();
    return switch (raw) {
      'png' => 'png',
      'webp' => 'webp',
      'heic' => 'heic',
      'heif' => 'heif',
      'jpeg' => 'jpg',
      'jpg' => 'jpg',
      _ => 'jpg',
    };
  }
}

class _DisplayNameParts {
  const _DisplayNameParts({this.firstName = '', this.lastName = ''});

  final String firstName;
  final String lastName;
}
