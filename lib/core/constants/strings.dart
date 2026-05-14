abstract class AppStrings {
  // ─── App ────────────────────────────────────────────────────
  static const String appName = 'Wafi';
  static const String appTagline = 'Shop Smart. Shop Wafi.';
  static const String appVersion = '1.0.0';

  // ─── General ────────────────────────────────────────────────
  static const String ok = 'OK';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String save = 'Save';
  static const String update = 'Update';
  static const String delete = 'Delete';
  static const String retry = 'Try Again';
  static const String close = 'Close';
  static const String next = 'Next';
  static const String back = 'Back';
  static const String done = 'Done';
  static const String skip = 'Skip';
  static const String search = 'Search';
  static const String filter = 'Filter';
  static const String sortBy = 'Sort by';
  static const String seeAll = 'See All';
  static const String loading = 'Loading...';
  static const String noData = 'Nothing here yet';
  static const String comingSoon = 'Coming soon';

  // ─── Auth ────────────────────────────────────────────────────
  static const String login = 'Log In';
  static const String signup = 'Create Account';
  static const String logout = 'Log Out';
  static const String logoutConfirm = 'Are you sure you want to log out?';

  static const String welcomeBack = 'Welcome back!';
  static const String createAccount = 'Create your account';

  static const String email = 'Email';
  static const String emailHint = 'you@example.com';
  static const String password = 'Password';
  static const String passwordHint = 'Min. 8 characters';
  static const String confirmPass = 'Confirm Password';
  static const String firstName = 'First Name';
  static const String lastName = 'Last Name';
  static const String phone = 'Phone Number';
  static const String phoneHint = '01XXXXXXXXX';

  static const String continueGoogle = 'Continue with Google';
  static const String continueGuest = 'Browse as Guest';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String resetSent = 'Reset link sent to your email.';

  static const String alreadyHaveAcc = 'Already have an account? ';
  static const String dontHaveAcc = "Don't have an account? ";

  static const String orContinueWith = 'or continue with';

  static const String guestBannerMsg =
      'You are browsing as a guest. Log in to checkout.';
  static const String loginToCheckout = 'Please log in to continue.';

  // ─── Validation Messages ────────────────────────────────────
  static const String validEmail = 'Enter a valid email';
  static const String validPassword = 'Password must be at least 8 characters';
  static const String validPassMatch = 'Passwords do not match';
  static const String validRequired = 'This field is required';
  static const String validPhone = 'Enter a valid phone number';
  static const String validName = 'Name must be at least 2 characters';

  // ─── Profile ─────────────────────────────────────────────────
  static const String profile = 'Profile';
  static const String editProfile = 'Edit Profile';
  static const String profilePicture = 'Profile Picture';
  static const String changePhoto = 'Change Photo';
  static const String myAccount = 'My Account';

  // ─── Address ─────────────────────────────────────────────────
  static const String addresses = 'My Addresses';
  static const String addAddress = 'Add Address';
  static const String editAddress = 'Edit Address';
  static const String deleteAddress = 'Delete this address?';
  static const String addressLine1 = 'Address Line 1';
  static const String addressLine2 = 'Address Line 2 (optional)';
  static const String city = 'City';
  static const String postalCode = 'Postal Code';
  static const String country = 'Country';
  static const String setDefault = 'Set as default';
  static const String defaultAddress = 'Default';
  static const String addressHome = 'Home';
  static const String addressOffice = 'Office';
  static const String addressOther = 'Other';
  static const String maxAddress = 'You can add up to 5 addresses only.';

  // ─── Products ────────────────────────────────────────────────
  static const String products = 'Products';
  static const String newArrivals = 'New Arrivals';
  static const String featured = 'Featured';
  static const String topRated = 'Top Rated';
  static const String bestsellers = 'Best Sellers';
  static const String onSale = 'On Sale';
  static const String inStock = 'In Stock';
  static const String outOfStock = 'Out of Stock';
  static const String lowStock = 'Only {count} left!';
  static const String sku = 'SKU';
  static const String productDetails = 'Product Details';
  static const String description = 'Description';
  static const String reviews = 'Reviews';
  static const String rating = 'Rating';
  static const String noReviews = 'No reviews yet. Be the first!';
  static const String writeReview = 'Write a Review';
  static const String editReview = 'Edit Review';
  static const String reviewTitle = 'Review Title';
  static const String reviewComment = 'Review Comment';
  static const String verifiedPurchase = 'Verified Purchase';
  static const categories = 'Categories';
  static const home = 'Home';
  // ─── Cart ────────────────────────────────────────────────────
  static const String cart = 'Cart';
  static const String myCart = 'My Cart';
  static const String wishlist = 'Wishlist';
  static const String myWishlist = 'My Wishlist';
  static const String addToCart = 'Add to Cart';
  static const String removeFromCart = 'Remove';
  static const String addToWishlist = 'Add to Wishlist';
  static const String removeFromWishlist = 'Remove from Wishlist';
  static const String cartEmpty = 'Your cart is empty';
  static const String cartEmptySub = 'Start shopping to add items';
  static const String cartMerged = 'Your guest cart has been saved.';
  static const String continueShopping = 'Continue Shopping';
  static const String quantity = 'Quantity';
  static const String subtotal = 'Subtotal';
  static const String total = 'Total';
  static const String tax = 'Tax';

  // ─── Checkout ────────────────────────────────────────────────
  static const String checkout = 'Checkout';
  static const String placeOrder = 'Place Order';
  static const String orderSummary = 'Order Summary';
  static const String deliveryAddress = 'Delivery Address';
  static const String paymentMethod = 'Payment Method';
  static const String deliveryNotes = 'Delivery Notes (optional)';
  static const String deliveryNotesHint = 'Any special instructions...';

  // ─── Payment ─────────────────────────────────────────────────
  static const String cod = 'Cash on Delivery';
  static const String codDesc = 'Pay when your order arrives.';
  static const String bkash = 'bKash';
  static const String bkashDesc = 'Demo mode — no real charges.';
  static const String bkashDemo = '⚠ bKash is in demo mode.';
  static const String paymentSuccess = 'Payment Successful!';
  static const String paymentFailed = 'Payment Failed. Please try again.';

  // ─── Orders ──────────────────────────────────────────────────
  static const String orders = 'My Orders';
  static const String orderHistory = 'Order History';
  static const String orderDetails = 'Order Details';
  static const String orderId = 'Order ID';
  static const String orderDate = 'Order Date';
  static const String orderSuccess = 'Order Placed!';
  static const String orderSuccessSub = 'We will confirm your order shortly.';
  static const String reorder = 'Reorder';
  static const String cancelOrder = 'Cancel Order';
  static const String cancelConfirm = 'Cancel this order?';
  static const String noOrders = 'No orders yet';
  static const String trackOrder = 'Track Order';
  static const myOrders = 'My Orders';
  // ─── Order Status ────────────────────────────────────────────
  static const String statusPending = 'Pending';
  static const String statusConfirmed = 'Confirmed';
  static const String statusShipped = 'Shipped';
  static const String statusDelivered = 'Delivered';
  static const String statusCancelled = 'Cancelled';

  // ─── Shop Owner Dashboard ────────────────────────────────────
  static const String dashboard = 'Dashboard';
  static const String totalOrders = 'Total Orders';
  static const String totalRevenue = 'Total Revenue';
  static const String totalProducts = 'Total Products';
  static const String pendingOrders = 'Pending Orders';
  static const String addProduct = 'Add Product';
  static const String editProduct = 'Edit';
  static const String deleteProduct = 'Delete Product';
  static const String deleteProductConfirm = 'Delete this product permanently?';
  static const String productName = 'Product Name';
  static const String price = 'Price';
  static const String originalPrice = 'Original Price';
  static const String stockQty = 'Stock Quantity';
  static const String lowStockAlert = 'Low Stock Alert';
  static const String category = 'Category';
  static const String subcategory = 'Subcategory';
  static const String uploadImages = 'Upload Images';
  static const String shortDesc = 'Short Description';
  static const String fullDesc = 'Full Description';
  static const String manageOrders = 'Manage Orders';
  static const String confirmOrder = 'Confirm Order';
  static const String shipOrder = 'Mark as Shipped';
  static const String deliverOrder = 'Mark as Delivered';
  static const String inventory = 'Inventory';
  static const String adjustStock = 'Adjust Stock';

  // ─── Settings ────────────────────────────────────────────────
  static const String settings = 'Settings';
  static const String darkMode = 'Dark Mode';
  static const String lightMode = 'Light Mode';
  static const String language = 'Language';
  static const String notifications = 'Notifications';
  static const String privacy = 'Privacy Policy';
  static const String terms = 'Terms of Service';
  static const String about = 'About Wafi';
  static const String version = 'Version';

  // ─── Errors ──────────────────────────────────────────────────
  static const String errGeneral = 'Something went wrong. Please try again.';
  static const String errNetwork = 'No internet connection.';
  static const String errTimeout = 'Connection timed out.';
  static const String errUnauthorized = 'Session expired. Please log in again.';
  static const String errNotFound = 'Not found.';
  static const String errServer = 'Server error. Try again later.';
  static const String errEmailInUse = 'This email is already registered.';
  static const String errWrongPass = 'Incorrect email or password.';
  static const String errWeakPass = 'Please choose a stronger password.';
  static const String errGoogleLogin = 'Google sign-in failed. Try again.';
  static const String errStockLimit = 'Not enough stock available.';
  static const String errCartMax = 'You cannot add more than 20 items.';
  static const String errProductUnavailable = 'This product is not available.';
  static const String errOutOfStock = 'This product is out of stock.';
  static const String errQuantityLimit = 'Quantity limit reached.';

  // ─── Empty States ────────────────────────────────────────────
  static const String emptyCart = 'Your cart is empty';
  static const String emptyWishlist = 'Your wishlist is empty';
  static const String emptyWishlistSub =
      'Tap the heart icon to save products you like';
  static const String emptyOrders = 'You have no orders yet';
  static const String emptyProducts = 'No products found';
  static const String emptySearch = 'No results for your search';
  static const String emptyAddress = 'No saved addresses';

  // ─── Notifications ───────────────────────────────────────────
  static const String notifOrderConf = 'Your order has been confirmed!';
  static const String notifOrderShip = 'Your order is on the way!';
  static const String notifOrderDel = 'Your order has been delivered!';
  static const String notifLowStock = 'Low stock alert for {product}';
  static const String notifNewOrder = 'New order received!';

  // ─── Currency ────────────────────────────────────────────────
  static const String currencySymbol = '৳';
  static const String currencyCode = 'BDT';
  static const String free = 'FREE';
}
