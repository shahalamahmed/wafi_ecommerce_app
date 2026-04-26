// lib/seed/wafi_seeder.dart
//
// Wafi Ecommerce – Firebase Firestore Seeder (Flutter/Dart)
// ══════════════════════════════════════════════════════════
// কিভাবে ব্যবহার করবেন:
//   যেকোনো জায়গা থেকে call করুন (যেমন একটা debug button):
//
//   ElevatedButton(
//     onPressed: () => WafiSeeder.seed(),
//     child: Text('Seed Firebase'),
//   )
//
// pubspec.yaml dependencies দরকার:
//   cloud_firestore: ^5.0.0
//   firebase_core: ^3.0.0

import 'package:cloud_firestore/cloud_firestore.dart';

class WafiSeeder {
  static final _db = FirebaseFirestore.instance;

  // ─── Entry Point ──────────────────────────────────────────
  static Future<void> seed() async {
    print('🌱 Wafi Seeder শুরু হচ্ছে...');

    await _seedUsers();
    await _seedAddresses();
    await _seedCategories();
    await _seedProducts();
    await _seedReviews();
    await _seedCarts();
    await _seedOrders();

    print('🎉 সব ডেটা সফলভাবে Firebase-এ আপলোড হয়েছে!');
  }

  // ─── Helper ───────────────────────────────────────────────
  static Future<void> _seedCollection(
      String collectionName,
      List<Map<String, dynamic>> docs,
      ) async {
    final col = _db.collection(collectionName);
    final batch = _db.batch();

    for (final doc in docs) {
      final id = doc['id'] as String;
      final data = doc['data'] as Map<String, dynamic>;
      batch.set(col.doc(id), data);
    }

    await batch.commit();
    print('✅ $collectionName: ${docs.length} documents seeded');
  }

  static Timestamp _daysAgo(int days) {
    final date = DateTime.now().subtract(Duration(days: days));
    return Timestamp.fromDate(date);
  }

  // ══════════════════════════════════════════════════════════
  // 1. USERS
  // ══════════════════════════════════════════════════════════
  static Future<void> _seedUsers() async {
    final docs = [
      {
        'id': 'owner_uid_001',
        'data': {
          'firstName': 'Rahim',
          'lastName': 'Uddin',
          'email': 'owner@wafi.com',
          'phone': '01711000001',
          'profilePicture': '',
          'role': 'owner',
          'isShopOwner': true,
          'shopName': 'Wafi Shop',
          'createdAt': _daysAgo(60),
          'updatedAt': _daysAgo(60),
        },
      },
      {
        'id': 'customer_uid_001',
        'data': {
          'firstName': 'Nadia',
          'lastName': 'Hossain',
          'email': 'nadia@example.com',
          'phone': '01811000002',
          'profilePicture': '',
          'role': 'customer',
          'isShopOwner': false,
          'shopName': '',
          'createdAt': _daysAgo(30),
          'updatedAt': _daysAgo(10),
        },
      },
      {
        'id': 'customer_uid_002',
        'data': {
          'firstName': 'Karim',
          'lastName': 'Molla',
          'email': 'karim@example.com',
          'phone': '01911000003',
          'profilePicture': '',
          'role': 'customer',
          'isShopOwner': false,
          'shopName': '',
          'createdAt': _daysAgo(20),
          'updatedAt': _daysAgo(5),
        },
      },
    ];
    await _seedCollection('users', docs);
  }

  // ══════════════════════════════════════════════════════════
  // 2. ADDRESSES
  // ══════════════════════════════════════════════════════════
  static Future<void> _seedAddresses() async {
    final docs = [
      {
        'id': 'addr_001',
        'data': {
          'userId': 'customer_uid_001',
          'type': 'home',
          'addressLine1': 'House 12, Road 4',
          'addressLine2': 'Dhanmondi',
          'city': 'Dhaka',
          'postalCode': '1205',
          'country': 'Bangladesh',
          'isDefault': true,
          'createdAt': _daysAgo(30),
        },
      },
      {
        'id': 'addr_002',
        'data': {
          'userId': 'customer_uid_001',
          'type': 'office',
          'addressLine1': 'Plot 5, Sector 3',
          'addressLine2': 'Uttara',
          'city': 'Dhaka',
          'postalCode': '1230',
          'country': 'Bangladesh',
          'isDefault': false,
          'createdAt': _daysAgo(15),
        },
      },
      {
        'id': 'addr_003',
        'data': {
          'userId': 'customer_uid_002',
          'type': 'home',
          'addressLine1': 'Flat 3B, Bashundhara R/A',
          'addressLine2': '',
          'city': 'Dhaka',
          'postalCode': '1229',
          'country': 'Bangladesh',
          'isDefault': true,
          'createdAt': _daysAgo(20),
        },
      },
    ];
    await _seedCollection('addresses', docs);
  }

  // ══════════════════════════════════════════════════════════
  // 3. CATEGORIES
  // ══════════════════════════════════════════════════════════
  static Future<void> _seedCategories() async {
    final docs = [
      // Top-level
      {
        'id': 'cat_electronics',
        'data': {
          'name': 'Electronics',
          'description': 'Gadgets, phones, and devices',
          'image': 'https://placehold.co/300x200?text=Electronics',
          'parentId': null,
          'displayOrder': 1,
          'isActive': true,
          'createdAt': _daysAgo(60),
        },
      },
      {
        'id': 'cat_fashion',
        'data': {
          'name': 'Fashion',
          'description': 'Clothing and accessories',
          'image': 'https://placehold.co/300x200?text=Fashion',
          'parentId': null,
          'displayOrder': 2,
          'isActive': true,
          'createdAt': _daysAgo(60),
        },
      },
      {
        'id': 'cat_home',
        'data': {
          'name': 'Home & Living',
          'description': 'Furniture, décor, and kitchen items',
          'image': 'https://placehold.co/300x200?text=Home',
          'parentId': null,
          'displayOrder': 3,
          'isActive': true,
          'createdAt': _daysAgo(60),
        },
      },
      // Sub-categories
      {
        'id': 'cat_phones',
        'data': {
          'name': 'Smartphones',
          'description': 'Latest smartphones',
          'image': 'https://placehold.co/300x200?text=Phones',
          'parentId': 'cat_electronics',
          'displayOrder': 1,
          'isActive': true,
          'createdAt': _daysAgo(60),
        },
      },
      {
        'id': 'cat_accessories',
        'data': {
          'name': 'Accessories',
          'description': 'Phone accessories',
          'image': 'https://placehold.co/300x200?text=Accessories',
          'parentId': 'cat_electronics',
          'displayOrder': 2,
          'isActive': true,
          'createdAt': _daysAgo(60),
        },
      },
      {
        'id': 'cat_menswear',
        'data': {
          'name': "Men's Clothing",
          'description': 'Shirts, pants, and more',
          'image': 'https://placehold.co/300x200?text=Menswear',
          'parentId': 'cat_fashion',
          'displayOrder': 1,
          'isActive': true,
          'createdAt': _daysAgo(60),
        },
      },
      {
        'id': 'cat_womenswear',
        'data': {
          'name': "Women's Clothing",
          'description': 'Sarees, kurtas, and more',
          'image': 'https://placehold.co/300x200?text=Womenswear',
          'parentId': 'cat_fashion',
          'displayOrder': 2,
          'isActive': true,
          'createdAt': _daysAgo(60),
        },
      },
    ];
    await _seedCollection('categories', docs);
  }

  // ══════════════════════════════════════════════════════════
  // 4. PRODUCTS
  // ══════════════════════════════════════════════════════════
  static Future<void> _seedProducts() async {
    final docs = [
      {
        'id': 'prod_001',
        'data': {
          'name': 'Samsung Galaxy A55',
          'description':
          'Samsung Galaxy A55 5G with 6.6-inch Super AMOLED display, 50MP camera, and 5000mAh battery.',
          'shortDescription': '5G smartphone with great camera',
          'sku': 'SAM-A55-BLK',
          'price': 35000.0,
          'originalPrice': 38000.0,
          'category': 'cat_electronics',
          'subCategory': 'cat_phones',
          'stock': 25,
          'lowStockThreshold': 5,
          'images': [
            'https://placehold.co/600x600?text=Galaxy+A55',
            'https://placehold.co/600x600?text=A55+Back',
          ],
          'rating': 4.5,
          'reviewCount': 12,
          'isActive': true,
          'createdAt': _daysAgo(45),
          'updatedAt': _daysAgo(2),
        },
      },
      {
        'id': 'prod_002',
        'data': {
          'name': 'Xiaomi Redmi Note 13',
          'description':
          'Redmi Note 13 with 108MP camera, 6.67-inch AMOLED, 5000mAh battery.',
          'shortDescription': 'High-res camera phone at great value',
          'sku': 'XMI-RN13-BLU',
          'price': 22000.0,
          'originalPrice': 24000.0,
          'category': 'cat_electronics',
          'subCategory': 'cat_phones',
          'stock': 40,
          'lowStockThreshold': 8,
          'images': ['https://placehold.co/600x600?text=Redmi+Note+13'],
          'rating': 4.3,
          'reviewCount': 8,
          'isActive': true,
          'createdAt': _daysAgo(30),
          'updatedAt': _daysAgo(1),
        },
      },
      {
        'id': 'prod_003',
        'data': {
          'name': 'USB-C Fast Charger 65W',
          'description':
          'GaN technology fast charger. Compatible with all USB-C devices.',
          'shortDescription': '65W GaN fast charger',
          'sku': 'CHG-65W-WHT',
          'price': 1500.0,
          'originalPrice': 2000.0,
          'category': 'cat_electronics',
          'subCategory': 'cat_accessories',
          'stock': 100,
          'lowStockThreshold': 20,
          'images': ['https://placehold.co/600x600?text=65W+Charger'],
          'rating': 4.7,
          'reviewCount': 35,
          'isActive': true,
          'createdAt': _daysAgo(50),
          'updatedAt': _daysAgo(10),
        },
      },
      {
        'id': 'prod_004',
        'data': {
          'name': 'Cotton Panjabi - White',
          'description':
          'Premium cotton panjabi for Eid and casual wear. Available in all sizes.',
          'shortDescription': 'Comfortable cotton panjabi',
          'sku': 'PNJ-COT-WHT-M',
          'price': 1200.0,
          'originalPrice': 1500.0,
          'category': 'cat_fashion',
          'subCategory': 'cat_menswear',
          'stock': 60,
          'lowStockThreshold': 10,
          'images': ['https://placehold.co/600x600?text=White+Panjabi'],
          'rating': 4.2,
          'reviewCount': 20,
          'isActive': true,
          'createdAt': _daysAgo(25),
          'updatedAt': _daysAgo(3),
        },
      },
      {
        'id': 'prod_005',
        'data': {
          'name': 'Jamdani Saree',
          'description':
          'Authentic Bangladeshi Jamdani saree, hand-woven by artisans from Narayanganj.',
          'shortDescription': 'Authentic hand-woven Jamdani',
          'sku': 'SAR-JAM-RED',
          'price': 5500.0,
          'originalPrice': 6000.0,
          'category': 'cat_fashion',
          'subCategory': 'cat_womenswear',
          'stock': 15,
          'lowStockThreshold': 3,
          'images': ['https://placehold.co/600x600?text=Jamdani+Saree'],
          'rating': 4.8,
          'reviewCount': 10,
          'isActive': true,
          'createdAt': _daysAgo(20),
          'updatedAt': _daysAgo(5),
        },
      },
      {
        'id': 'prod_006',
        'data': {
          'name': 'Wooden Bookshelf (5-tier)',
          'description':
          'Sturdy 5-tier wooden bookshelf. Easy to assemble. 180cm height.',
          'shortDescription': '5-tier home bookshelf',
          'sku': 'BOOK-5T-BRN',
          'price': 7500.0,
          'originalPrice': 9000.0,
          'category': 'cat_home',
          'subCategory': null,
          'stock': 10,
          'lowStockThreshold': 2,
          'images': ['https://placehold.co/600x600?text=Bookshelf'],
          'rating': 4.1,
          'reviewCount': 5,
          'isActive': true,
          'createdAt': _daysAgo(15),
          'updatedAt': _daysAgo(7),
        },
      },
    ];
    await _seedCollection('products', docs);
  }

  // ══════════════════════════════════════════════════════════
  // 5. REVIEWS
  // ══════════════════════════════════════════════════════════
  static Future<void> _seedReviews() async {
    final docs = [
      {
        'id': 'rev_001',
        'data': {
          'productId': 'prod_001',
          'userId': 'customer_uid_001',
          'rating': 5,
          'title': 'Excellent phone!',
          'comment':
          'Battery life is amazing. Camera quality is top-notch for the price.',
          'helpful': 4,
          'createdAt': _daysAgo(10),
        },
      },
      {
        'id': 'rev_002',
        'data': {
          'productId': 'prod_001',
          'userId': 'customer_uid_002',
          'rating': 4,
          'title': 'Good value',
          'comment':
          'Very good phone, minor heating issues but overall great experience.',
          'helpful': 2,
          'createdAt': _daysAgo(8),
        },
      },
      {
        'id': 'rev_003',
        'data': {
          'productId': 'prod_003',
          'userId': 'customer_uid_001',
          'rating': 5,
          'title': 'Charges super fast!',
          'comment':
          'Charges my phone from 0 to 100 in under 40 minutes. Highly recommend.',
          'helpful': 7,
          'createdAt': _daysAgo(12),
        },
      },
      {
        'id': 'rev_004',
        'data': {
          'productId': 'prod_005',
          'userId': 'customer_uid_002',
          'rating': 5,
          'title': 'Beautiful saree',
          'comment': 'Received exactly as shown. Very authentic, perfect for Eid.',
          'helpful': 5,
          'createdAt': _daysAgo(6),
        },
      },
    ];
    await _seedCollection('reviews', docs);
  }

  // ══════════════════════════════════════════════════════════
  // 6. CARTS
  // ══════════════════════════════════════════════════════════
  static Future<void> _seedCarts() async {
    final docs = [
      {
        'id': 'customer_uid_001', // Document ID = userId
        'data': {
          'userId': 'customer_uid_001',
          'items': [
            {
              'productId': 'prod_002',
              'quantity': 1,
              'price': 22000.0,
              'subtotal': 22000.0,
            },
            {
              'productId': 'prod_003',
              'quantity': 2,
              'price': 1500.0,
              'subtotal': 3000.0,
            },
          ],
          'subtotal': 25000.0,
          'tax': 1250.0,
          'total': 26250.0,
          'lastUpdated': Timestamp.now(),
        },
      },
    ];
    await _seedCollection('carts', docs);
  }

  // ══════════════════════════════════════════════════════════
  // 7. ORDERS
  // ══════════════════════════════════════════════════════════
  static Future<void> _seedOrders() async {
    final docs = [
      {
        'id': 'order_001',
        'data': {
          'orderId': 'WAFI-20240001',
          'userId': 'customer_uid_001',
          'items': [
            {
              'productId': 'prod_001',
              'productName': 'Samsung Galaxy A55',
              'quantity': 1,
              'price': 35000.0,
              'subtotal': 35000.0,
            },
          ],
          'status': 'delivered',
          'paymentMethod': 'bkash',
          'paymentStatus': 'paid',
          'deliveryAddress': {
            'type': 'home',
            'addressLine1': 'House 12, Road 4',
            'addressLine2': 'Dhanmondi',
            'city': 'Dhaka',
            'postalCode': '1205',
            'country': 'Bangladesh',
          },
          'subtotal': 35000.0,
          'tax': 1750.0,
          'total': 36750.0,
          'notes': 'Please ring the bell twice.',
          'createdAt': _daysAgo(25),
          'confirmedAt': _daysAgo(24),
          'shippedAt': _daysAgo(23),
          'deliveredAt': _daysAgo(21),
        },
      },
      {
        'id': 'order_002',
        'data': {
          'orderId': 'WAFI-20240002',
          'userId': 'customer_uid_002',
          'items': [
            {
              'productId': 'prod_004',
              'productName': 'Cotton Panjabi - White',
              'quantity': 2,
              'price': 1200.0,
              'subtotal': 2400.0,
            },
            {
              'productId': 'prod_005',
              'productName': 'Jamdani Saree',
              'quantity': 1,
              'price': 5500.0,
              'subtotal': 5500.0,
            },
          ],
          'status': 'shipped',
          'paymentMethod': 'cod',
          'paymentStatus': 'pending',
          'deliveryAddress': {
            'type': 'home',
            'addressLine1': 'Flat 3B, Bashundhara R/A',
            'addressLine2': '',
            'city': 'Dhaka',
            'postalCode': '1229',
            'country': 'Bangladesh',
          },
          'subtotal': 7900.0,
          'tax': 395.0,
          'total': 8295.0,
          'notes': '',
          'createdAt': _daysAgo(5),
          'confirmedAt': _daysAgo(4),
          'shippedAt': _daysAgo(3),
          'deliveredAt': null,
        },
      },
      {
        'id': 'order_003',
        'data': {
          'orderId': 'WAFI-20240003',
          'userId': 'customer_uid_001',
          'items': [
            {
              'productId': 'prod_006',
              'productName': 'Wooden Bookshelf (5-tier)',
              'quantity': 1,
              'price': 7500.0,
              'subtotal': 7500.0,
            },
          ],
          'status': 'pending',
          'paymentMethod': 'cod',
          'paymentStatus': 'pending',
          'deliveryAddress': {
            'type': 'office',
            'addressLine1': 'Plot 5, Sector 3',
            'addressLine2': 'Uttara',
            'city': 'Dhaka',
            'postalCode': '1230',
            'country': 'Bangladesh',
          },
          'subtotal': 7500.0,
          'tax': 375.0,
          'total': 7875.0,
          'notes': 'Deliver after 6pm please.',
          'createdAt': Timestamp.now(),
          'confirmedAt': null,
          'shippedAt': null,
          'deliveredAt': null,
        },
      },
    ];
    await _seedCollection('orders', docs);
  }
}