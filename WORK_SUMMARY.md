# Wafi Ecommerce Work Summary

## Overview
This file tracks the major implementation work completed in the current workspace so far.

## Completed Work

### 1. Auth foundation
- Added auth domain types in `lib/features/auth/auth_model.dart`
  - `AuthView`
  - `AuthStatus`
  - `UserRole`
  - `LoginCredentials`
  - `RegistrationData`
  - `AppUser`
  - `AuthState`
- Built Firebase-backed auth flow in `lib/features/auth/auth_service.dart`
  - email/password sign in
  - account registration
  - Google sign in
  - password reset
  - guest session support
  - guest cart merge hook
- Built Riverpod auth state management in `lib/features/auth/auth_provider.dart`
  - bootstrap
  - auth state listener
  - login/register/logout
  - guest mode

### 2. App shell and shared UI
- Built `lib/shared/layout/main_layout.dart`
  - drawer
  - bottom navigation
  - customer and owner shell split
  - theme controls
  - cart badge wiring
- Added reusable app bar in `lib/shared/widgets/wafi_app_bar.dart`
  - shared title/subtitle layout
  - profile avatar action on the right
- Built or refined shared glass UI components
  - `glass_bottom_nav.dart`
  - `glass_button.dart`
  - `glass_card.dart`
  - `glass_chip.dart`
  - `glass_input.dart`
  - `glass_snackbar.dart`
- Updated light theme glass border visibility in `lib/core/constants/colors.dart`

### 3. Products module
- Implemented `lib/features/products/product_model.dart`
  - `ProductCategory`
  - `ProductModel`
  - `ProductState`
  - filtering and derived helpers
- Implemented `lib/features/products/product_service.dart`
  - fetch active products from Firestore
  - fetch active categories from Firestore
- Implemented `lib/features/products/product_provider.dart`
  - load products and categories
  - category filter
  - subcategory filter
  - search query
  - stock filter
  - view mode
  - filter reset flow
- Implemented product UI
  - `lib/features/products/widgets/product_card.dart`
  - `lib/features/products/widgets/product_list.dart`
  - `lib/features/products/product_screen.dart`
- Added `ProductCatalogPage`
  - pushable product route with shared app bar
  - supports category-based opening from home
- Added `lib/features/products/product_details_screen.dart`
  - product image/details
  - pricing
  - stock state
  - add-to-cart CTA

### 4. Home screen
- Added `lib/features/home/home_screen.dart`
  - banner section
  - category section
  - most popular items
  - new arrivals
  - category `See All` action
  - category-based navigation into the product catalog
- Updated `MainLayout`
  - customer first tab is now `Home`
  - home links push filtered or full product catalog screens

### 5. Cart module
- Added cart domain in:
  - `lib/features/cart/cart_model.dart`
  - `lib/features/cart/cart_service.dart`
  - `lib/features/cart/cart_provider.dart`
- Built `lib/features/cart/cart_screen.dart`
  - item rows
  - quantity controls
  - remove flow
  - subtotal/tax/total summary
  - proceed button
- Cart storage flow supports:
  - guest cart persistence
  - signed-in cart persistence in Firestore
  - totals recalculation

### 6. Checkout and orders
- Added order domain in:
  - `lib/features/orders/order_model.dart`
  - `lib/features/orders/order_service.dart`
  - `lib/features/orders/order_provider.dart`
- Built `lib/features/orders/checkout_screen.dart`
  - delivery form
  - notes
  - delivery date
  - coupon placeholder
  - order summary
  - payment method section
  - place order action
- Built `lib/features/orders/order_screen.dart`
  - order history list
  - order details flow
- Wired cart `Proceed` into checkout
- Wired customer orders screen into the main shell

### 7. Profile and avatar flow
- Built/refined `lib/profile/profile_screen.dart`
  - profile overview
  - user information
  - profile actions
  - inline address display
- Added avatar fallback widget handling in `lib/shared/widgets/profile_avatar.dart`
  - invalid image URL fallback
  - initials fallback
- Improved profile picture update flow
  - upload path uses Firebase Storage
  - Firestore `users/{uid}.profilePicture` update support
  - auth state is preserved on upload failure

### 8. Address management
- Added address module
  - `lib/features/addresses/address_model.dart`
  - `lib/features/addresses/address_service.dart`
  - `lib/features/addresses/address_provider.dart`
  - `lib/features/addresses/address_screen.dart`
- Added reusable address form bottom sheet helper
- Added profile integration
  - if no address, show `My Addresses`
  - after add, show saved address card under user info
  - edit and delete actions available
  - if all addresses are deleted, `My Addresses` shows again

### 9. Settings
- Added:
  - `lib/features/settings/settings_provider.dart`
  - `lib/features/settings/settings_screen.dart`
- Implemented settings UI
  - theme mode
  - notification toggles
  - promotions toggle
  - language selection
  - privacy/terms/about actions
  - account/logout section

### 10. Schema documentation
- Added Firestore ERD sources:
  - `docs/firestore_schema_erd.drawio`
  - `docs/firestore_schema_erd.md`

### 11. Seeder and safety updates
- Hardened `tools/wafi-seed.js`
  - safer seeding flow
  - reference validation
  - merge-safe writes
- Updated `tools/package.json`
  - explicit seed scripts
- Disabled app-side seed execution path in `lib/seed/wafi_seeder.dart`

## Current Behavior Highlights
- Customer home tab now opens a grocery-style landing screen.
- `See All` from home opens the full product catalog.
- Clicking a category from home opens the product catalog filtered to that category.
- Product cards open product details and support add-to-cart.
- Cart can continue into checkout.
- Placed orders can be viewed from `My Orders`.
- Profile supports saved addresses and avatar UI fallback handling.

## Important Notes
- `pubspec.yaml` was updated earlier with additional packages such as `image_picker` and `intl`.
- A full verification pass was interrupted several times before completion.
- `flutter pub get`, analyzer, and an end-to-end runtime test pass should be run after the current feature set settles.

## Recommended Next Steps
1. Run `flutter pub get`.
2. Run `dart analyze` and fix remaining compile issues.
3. Verify home -> product -> cart -> checkout -> orders flow on device.
4. Verify Firebase Storage rules and final avatar upload behavior with a signed-in user.
5. Add owner-side product/order management screens.
