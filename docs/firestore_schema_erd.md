# Firestore Schema ERD

This diagram is based on the current Firestore seed source in `tools/wafi-seed.js`.

## Collections Included
- `users`
- `addresses`
- `categories`
- `products`
- `reviews`
- `carts`
- `orders`

## Validation Notes
- Direct FK-style references shown:
  - `addresses.userId -> users.id`
  - `products.category -> categories.id`
  - `products.subCategory -> categories.id`
  - `reviews.userId -> users.id`
  - `reviews.productId -> products.id`
  - `carts.userId -> users.id`
  - `orders.userId -> users.id`
- Embedded references shown as dashed links:
  - `carts.items[].productId -> products.id`
  - `orders.items[].productId -> products.id`
- Embedded structures intentionally kept inside parent collections:
  - `orders.deliveryAddress`
  - `carts.items[]`

## How To Use
1. Open `docs/firestore_schema_erd.drawio` in `draw.io` / `diagrams.net`.
2. Adjust spacing or colors only if needed for presentation.
3. Export as `PNG` and `PDF`.

## Repo Source
- Seeder: [tools/wafi-seed.js](/d:/Office-Projects/wafi_ecommerce_app/tools/wafi-seed.js:1)
