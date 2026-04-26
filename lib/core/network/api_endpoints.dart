class ApiEndpoints {
  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String googleLogin = '/auth/google-login';

  // Users
  static String userProfile(String uid) => '/users/$uid';

  // Addresses
  static const String addresses = '/addresses';
  static String address(String id) => '/addresses/$id';

  // Products
  static const String products = '/products';
  static String product(String id) => '/products/$id';

  // Cart
  static const String cart = '/cart';

  // Orders
  static const String orders = '/orders';
  static String order(String id) => '/orders/$id';
}