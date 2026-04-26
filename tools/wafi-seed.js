/**
 * Wafi Ecommerce - Firebase Firestore/Auth Seeder
 * ===============================================
 * Run: node wafi-seed.js
 *
 * Prerequisites:
 *   npm install
 *
 * Setup:
 *   Firebase Console -> Project Settings -> Service Accounts -> Generate New Private Key
 *   Save the file as serviceAccountKey.json in the same directory (tools/)
 *
 * Safety:
 *   This script is blocked in production by default.
 *   Use --allow-production only when you intentionally want to seed production.
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const args = new Set(process.argv.slice(2));
const allowProduction = args.has('--allow-production');

if (process.env.NODE_ENV === 'production' && !allowProduction) {
  console.error('Refusing to run seeder with NODE_ENV=production. Pass --allow-production to override.');
  process.exit(1);
}

const keyPath = path.join(__dirname, 'serviceAccountKey.json');
if (!fs.existsSync(keyPath)) {
  console.error('Missing serviceAccountKey.json in tools/. Follow the setup instructions.');
  process.exit(1);
}

const serviceAccount = require(keyPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const ts = (date = new Date()) => admin.firestore.Timestamp.fromDate(date);
const daysAgo = (n) => {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return ts(d);
};

const users = [
  {
    id: 'owner_uid_001',
    auth: {
      email: 'owner@wafi.com',
      password: 'Owner123!',
      displayName: 'Rahim Uddin',
      customClaims: { role: 'owner', isShopOwner: true },
    },
    data: {
      firstName: 'Rahim',
      lastName: 'Uddin',
      email: 'owner@wafi.com',
      phone: '01711000001',
      profilePicture: '',
      role: 'owner',
      isShopOwner: true,
      shopName: 'Wafi Shop',
      createdAt: daysAgo(60),
      updatedAt: daysAgo(60),
    },
  },
  {
    id: 'customer_uid_001',
    auth: {
      email: 'nadia@example.com',
      password: 'Customer123!',
      displayName: 'Nadia Hossain',
      customClaims: { role: 'customer', isShopOwner: false },
    },
    data: {
      firstName: 'Nadia',
      lastName: 'Hossain',
      email: 'nadia@example.com',
      phone: '01811000002',
      profilePicture: '',
      role: 'customer',
      isShopOwner: false,
      shopName: '',
      createdAt: daysAgo(30),
      updatedAt: daysAgo(10),
    },
  },
  {
    id: 'customer_uid_002',
    auth: {
      email: 'karim@example.com',
      password: 'Customer123!',
      displayName: 'Karim Molla',
      customClaims: { role: 'customer', isShopOwner: false },
    },
    data: {
      firstName: 'Karim',
      lastName: 'Molla',
      email: 'karim@example.com',
      phone: '01911000003',
      profilePicture: '',
      role: 'customer',
      isShopOwner: false,
      shopName: '',
      createdAt: daysAgo(20),
      updatedAt: daysAgo(5),
    },
  },
];

const addresses = [
  {
    id: 'addr_001',
    data: {
      userId: 'customer_uid_001',
      type: 'home',
      addressLine1: 'House 12, Road 4',
      addressLine2: 'Dhanmondi',
      city: 'Dhaka',
      postalCode: '1205',
      country: 'Bangladesh',
      isDefault: true,
      createdAt: daysAgo(30),
    },
  },
  {
    id: 'addr_002',
    data: {
      userId: 'customer_uid_001',
      type: 'office',
      addressLine1: 'Plot 5, Sector 3',
      addressLine2: 'Uttara',
      city: 'Dhaka',
      postalCode: '1230',
      country: 'Bangladesh',
      isDefault: false,
      createdAt: daysAgo(15),
    },
  },
  {
    id: 'addr_003',
    data: {
      userId: 'customer_uid_002',
      type: 'home',
      addressLine1: 'Flat 3B, Bashundhara R/A',
      addressLine2: '',
      city: 'Dhaka',
      postalCode: '1229',
      country: 'Bangladesh',
      isDefault: true,
      createdAt: daysAgo(20),
    },
  },
];

const categories = [
  {
    id: 'cat_electronics',
    data: {
      name: 'Electronics',
      description: 'Gadgets, phones, and devices',
      image: 'https://placehold.co/300x200?text=Electronics',
      parentId: null,
      displayOrder: 1,
      isActive: true,
      createdAt: daysAgo(60),
    },
  },
  {
    id: 'cat_fashion',
    data: {
      name: 'Fashion',
      description: 'Clothing and accessories',
      image: 'https://placehold.co/300x200?text=Fashion',
      parentId: null,
      displayOrder: 2,
      isActive: true,
      createdAt: daysAgo(60),
    },
  },
  {
    id: 'cat_home',
    data: {
      name: 'Home & Living',
      description: 'Furniture, decor, and kitchen items',
      image: 'https://placehold.co/300x200?text=Home',
      parentId: null,
      displayOrder: 3,
      isActive: true,
      createdAt: daysAgo(60),
    },
  },
  {
    id: 'cat_phones',
    data: {
      name: 'Smartphones',
      description: 'Latest smartphones',
      image: 'https://placehold.co/300x200?text=Phones',
      parentId: 'cat_electronics',
      displayOrder: 1,
      isActive: true,
      createdAt: daysAgo(60),
    },
  },
  {
    id: 'cat_accessories',
    data: {
      name: 'Accessories',
      description: 'Phone accessories',
      image: 'https://placehold.co/300x200?text=Accessories',
      parentId: 'cat_electronics',
      displayOrder: 2,
      isActive: true,
      createdAt: daysAgo(60),
    },
  },
  {
    id: 'cat_menswear',
    data: {
      name: "Men's Clothing",
      description: 'Shirts, pants, and more',
      image: 'https://placehold.co/300x200?text=Menswear',
      parentId: 'cat_fashion',
      displayOrder: 1,
      isActive: true,
      createdAt: daysAgo(60),
    },
  },
  {
    id: 'cat_womenswear',
    data: {
      name: "Women's Clothing",
      description: 'Sarees, kurtas, and more',
      image: 'https://placehold.co/300x200?text=Womenswear',
      parentId: 'cat_fashion',
      displayOrder: 2,
      isActive: true,
      createdAt: daysAgo(60),
    },
  },
];

const products = [
  {
    id: 'prod_001',
    data: {
      name: 'Samsung Galaxy A55',
      description:
        'Samsung Galaxy A55 5G with 6.6-inch Super AMOLED display, 50MP camera, and 5000mAh battery.',
      shortDescription: '5G smartphone with great camera',
      sku: 'SAM-A55-BLK',
      price: 35000,
      originalPrice: 38000,
      category: 'cat_electronics',
      subCategory: 'cat_phones',
      stock: 25,
      lowStockThreshold: 5,
      images: [
        'https://placehold.co/600x600?text=Galaxy+A55',
        'https://placehold.co/600x600?text=A55+Back',
      ],
      rating: 4.5,
      reviewCount: 12,
      isActive: true,
      createdAt: daysAgo(45),
      updatedAt: daysAgo(2),
    },
  },
  {
    id: 'prod_002',
    data: {
      name: 'Xiaomi Redmi Note 13',
      description: 'Redmi Note 13 with 108MP camera, 6.67-inch AMOLED, 5000mAh battery.',
      shortDescription: 'High-res camera phone at great value',
      sku: 'XMI-RN13-BLU',
      price: 22000,
      originalPrice: 24000,
      category: 'cat_electronics',
      subCategory: 'cat_phones',
      stock: 40,
      lowStockThreshold: 8,
      images: ['https://placehold.co/600x600?text=Redmi+Note+13'],
      rating: 4.3,
      reviewCount: 8,
      isActive: true,
      createdAt: daysAgo(30),
      updatedAt: daysAgo(1),
    },
  },
  {
    id: 'prod_003',
    data: {
      name: 'USB-C Fast Charger 65W',
      description: 'GaN technology fast charger. Compatible with all USB-C devices.',
      shortDescription: '65W GaN fast charger',
      sku: 'CHG-65W-WHT',
      price: 1500,
      originalPrice: 2000,
      category: 'cat_electronics',
      subCategory: 'cat_accessories',
      stock: 100,
      lowStockThreshold: 20,
      images: ['https://placehold.co/600x600?text=65W+Charger'],
      rating: 4.7,
      reviewCount: 35,
      isActive: true,
      createdAt: daysAgo(50),
      updatedAt: daysAgo(10),
    },
  },
  {
    id: 'prod_004',
    data: {
      name: 'Cotton Panjabi - White',
      description: 'Premium cotton panjabi for Eid and casual wear. Available in all sizes.',
      shortDescription: 'Comfortable cotton panjabi',
      sku: 'PNJ-COT-WHT-M',
      price: 1200,
      originalPrice: 1500,
      category: 'cat_fashion',
      subCategory: 'cat_menswear',
      stock: 60,
      lowStockThreshold: 10,
      images: ['https://placehold.co/600x600?text=White+Panjabi'],
      rating: 4.2,
      reviewCount: 20,
      isActive: true,
      createdAt: daysAgo(25),
      updatedAt: daysAgo(3),
    },
  },
  {
    id: 'prod_005',
    data: {
      name: 'Jamdani Saree',
      description: 'Authentic Bangladeshi Jamdani saree, hand-woven by artisans from Narayanganj.',
      shortDescription: 'Authentic hand-woven Jamdani',
      sku: 'SAR-JAM-RED',
      price: 5500,
      originalPrice: 6000,
      category: 'cat_fashion',
      subCategory: 'cat_womenswear',
      stock: 15,
      lowStockThreshold: 3,
      images: ['https://placehold.co/600x600?text=Jamdani+Saree'],
      rating: 4.8,
      reviewCount: 10,
      isActive: true,
      createdAt: daysAgo(20),
      updatedAt: daysAgo(5),
    },
  },
  {
    id: 'prod_006',
    data: {
      name: 'Wooden Bookshelf (5-tier)',
      description: 'Sturdy 5-tier wooden bookshelf. Easy to assemble. 180cm height.',
      shortDescription: '5-tier home bookshelf',
      sku: 'BOOK-5T-BRN',
      price: 7500,
      originalPrice: 9000,
      category: 'cat_home',
      subCategory: null,
      stock: 10,
      lowStockThreshold: 2,
      images: ['https://placehold.co/600x600?text=Bookshelf'],
      rating: 4.1,
      reviewCount: 5,
      isActive: true,
      createdAt: daysAgo(15),
      updatedAt: daysAgo(7),
    },
  },
];

const reviews = [
  {
    id: 'rev_001',
    data: {
      productId: 'prod_001',
      userId: 'customer_uid_001',
      rating: 5,
      title: 'Excellent phone!',
      comment: 'Battery life is amazing. Camera quality is top-notch for the price.',
      helpful: 4,
      createdAt: daysAgo(10),
    },
  },
  {
    id: 'rev_002',
    data: {
      productId: 'prod_001',
      userId: 'customer_uid_002',
      rating: 4,
      title: 'Good value',
      comment: 'Very good phone, minor heating issues but overall great experience.',
      helpful: 2,
      createdAt: daysAgo(8),
    },
  },
  {
    id: 'rev_003',
    data: {
      productId: 'prod_003',
      userId: 'customer_uid_001',
      rating: 5,
      title: 'Charges super fast!',
      comment: 'Charges my phone from 0 to 100 in under 40 minutes. Highly recommend.',
      helpful: 7,
      createdAt: daysAgo(12),
    },
  },
  {
    id: 'rev_004',
    data: {
      productId: 'prod_005',
      userId: 'customer_uid_002',
      rating: 5,
      title: 'Beautiful saree',
      comment: 'Received exactly as shown. Very authentic, perfect for Eid.',
      helpful: 5,
      createdAt: daysAgo(6),
    },
  },
];

const carts = [
  {
    id: 'customer_uid_001',
    data: {
      userId: 'customer_uid_001',
      items: [
        { productId: 'prod_002', quantity: 1, price: 22000, subtotal: 22000 },
        { productId: 'prod_003', quantity: 2, price: 1500, subtotal: 3000 },
      ],
      subtotal: 25000,
      tax: 1250,
      total: 26250,
      lastUpdated: ts(),
    },
  },
];

const orders = [
  {
    id: 'order_001',
    data: {
      orderId: 'WAFI-20240001',
      userId: 'customer_uid_001',
      items: [
        { productId: 'prod_001', productName: 'Samsung Galaxy A55', quantity: 1, price: 35000, subtotal: 35000 },
      ],
      status: 'delivered',
      paymentMethod: 'bkash',
      paymentStatus: 'paid',
      deliveryAddress: {
        type: 'home',
        addressLine1: 'House 12, Road 4',
        addressLine2: 'Dhanmondi',
        city: 'Dhaka',
        postalCode: '1205',
        country: 'Bangladesh',
      },
      subtotal: 35000,
      tax: 1750,
      total: 36750,
      notes: 'Please ring the bell twice.',
      createdAt: daysAgo(25),
      confirmedAt: daysAgo(24),
      shippedAt: daysAgo(23),
      deliveredAt: daysAgo(21),
    },
  },
  {
    id: 'order_002',
    data: {
      orderId: 'WAFI-20240002',
      userId: 'customer_uid_002',
      items: [
        { productId: 'prod_004', productName: 'Cotton Panjabi - White', quantity: 2, price: 1200, subtotal: 2400 },
        { productId: 'prod_005', productName: 'Jamdani Saree', quantity: 1, price: 5500, subtotal: 5500 },
      ],
      status: 'shipped',
      paymentMethod: 'cod',
      paymentStatus: 'pending',
      deliveryAddress: {
        type: 'home',
        addressLine1: 'Flat 3B, Bashundhara R/A',
        addressLine2: '',
        city: 'Dhaka',
        postalCode: '1229',
        country: 'Bangladesh',
      },
      subtotal: 7900,
      tax: 395,
      total: 8295,
      notes: '',
      createdAt: daysAgo(5),
      confirmedAt: daysAgo(4),
      shippedAt: daysAgo(3),
      deliveredAt: null,
    },
  },
  {
    id: 'order_003',
    data: {
      orderId: 'WAFI-20240003',
      userId: 'customer_uid_001',
      items: [
        { productId: 'prod_006', productName: 'Wooden Bookshelf (5-tier)', quantity: 1, price: 7500, subtotal: 7500 },
      ],
      status: 'pending',
      paymentMethod: 'cod',
      paymentStatus: 'pending',
      deliveryAddress: {
        type: 'office',
        addressLine1: 'Plot 5, Sector 3',
        addressLine2: 'Uttara',
        city: 'Dhaka',
        postalCode: '1230',
        country: 'Bangladesh',
      },
      subtotal: 7500,
      tax: 375,
      total: 7875,
      notes: 'Deliver after 6pm please.',
      createdAt: ts(),
      confirmedAt: null,
      shippedAt: null,
      deliveredAt: null,
    },
  },
];

function assertValid(condition, message) {
  if (!condition) {
    throw new Error(`Seed validation failed: ${message}`);
  }
}

function validateMoneyTotals(label, items, subtotal, total, tax) {
  const computedSubtotal = items.reduce((sum, item) => sum + item.subtotal, 0);
  assertValid(computedSubtotal === subtotal, `${label} subtotal mismatch`);
  assertValid(subtotal + tax === total, `${label} total mismatch`);
}

function validateReferences() {
  const userIds = new Set(users.map((entry) => entry.id));
  const categoryIds = new Set(categories.map((entry) => entry.id));
  const productIds = new Set(products.map((entry) => entry.id));

  for (const { id, data } of addresses) {
    assertValid(userIds.has(data.userId), `addresses/${id} -> missing user ${data.userId}`);
  }

  for (const { id, data } of categories) {
    if (data.parentId != null) {
      assertValid(categoryIds.has(data.parentId), `categories/${id} -> missing parent ${data.parentId}`);
    }
  }

  for (const { id, data } of products) {
    assertValid(categoryIds.has(data.category), `products/${id} -> missing category ${data.category}`);
    if (data.subCategory != null) {
      assertValid(categoryIds.has(data.subCategory), `products/${id} -> missing subCategory ${data.subCategory}`);
    }
  }

  for (const { id, data } of reviews) {
    assertValid(productIds.has(data.productId), `reviews/${id} -> missing product ${data.productId}`);
    assertValid(userIds.has(data.userId), `reviews/${id} -> missing user ${data.userId}`);
  }

  for (const { id, data } of carts) {
    assertValid(userIds.has(data.userId), `carts/${id} -> missing user ${data.userId}`);
    validateMoneyTotals(`carts/${id}`, data.items, data.subtotal, data.total, data.tax);
    for (const item of data.items) {
      assertValid(productIds.has(item.productId), `carts/${id} -> missing product ${item.productId}`);
    }
  }

  for (const { id, data } of orders) {
    assertValid(userIds.has(data.userId), `orders/${id} -> missing user ${data.userId}`);
    validateMoneyTotals(`orders/${id}`, data.items, data.subtotal, data.total, data.tax);
    for (const item of data.items) {
      assertValid(productIds.has(item.productId), `orders/${id} -> missing product ${item.productId}`);
    }
  }
}

function toE164(localPhone) {
  const digits = String(localPhone).replace(/\D/g, '');
  if (digits.startsWith('880')) return `+${digits}`;
  if (digits.startsWith('0')) return `+88${digits}`;
  return `+${digits}`;
}

async function seedAuthUsers() {
  let count = 0;

  for (const user of users) {
    const { id, auth, data } = user;

    try {
      await admin.auth().getUser(id);
      await admin.auth().updateUser(id, {
        email: auth.email,
        password: auth.password,
        displayName: auth.displayName,
        phoneNumber: toE164(data.phone),
      });
    } catch (error) {
      if (error.code !== 'auth/user-not-found') {
        throw error;
      }

      await admin.auth().createUser({
        uid: id,
        email: auth.email,
        password: auth.password,
        displayName: auth.displayName,
        phoneNumber: toE164(data.phone),
      });
    }

    await admin.auth().setCustomUserClaims(id, auth.customClaims);
    count++;
  }

  console.log(`Seeded Firebase Auth users: ${count}`);
}

async function seedCollection(collectionName, docs) {
  const col = db.collection(collectionName);
  const batch = db.batch();

  for (const { id, data } of docs) {
    batch.set(col.doc(id), data, { merge: true });
  }

  await batch.commit();
  console.log(`Seeded ${collectionName}: ${docs.length} documents`);
}

async function main() {
  console.log('Starting Wafi seeder...\n');

  validateReferences();
  await seedAuthUsers();

  await seedCollection('users', users);
  await seedCollection('addresses', addresses);
  await seedCollection('categories', categories);
  await seedCollection('products', products);
  await seedCollection('reviews', reviews);
  await seedCollection('carts', carts);
  await seedCollection('orders', orders);

  console.log('\nWafi seeding completed successfully.');
  process.exit(0);
}

main().catch((err) => {
  console.error('Seeding failed:', err);
  process.exit(1);
});
