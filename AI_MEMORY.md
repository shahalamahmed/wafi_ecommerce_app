# Wafi Ecommerce - AI Memory File

This file serves as a persistent context for AI coding assistants. It tracks the project's architecture, state, and development progress.

## 🚀 Project Overview
- **Name:** Wafi Ecommerce
- **Description:** A Flutter-based ecommerce application with a Firebase backend.
- **Project ID:** `wafi-ecommerce`

## 🛠 Tech Stack
- **Framework:** Flutter (Dart)
- **Backend:** Firebase (Firestore, Auth)
- **State Management:** Riverpod (`flutter_riverpod`)
- **Routing:** GoRouter (`go_router`)
- **Networking:** Dio (`dio`)

## 📁 Key Directories & Files
- `lib/main.dart`: Entry point, Firebase initialization, and temporary Seeder UI.
- `lib/seed/wafi_seeder.dart`: Main data seeding logic for Firestore.
- `tools/wafi-seed.js`: Node.js version of the data seeder (requires `serviceAccountKey.json`).
- `lib/firebase_options.dart`: Firebase configuration for Android and iOS.

## 💾 Data Seeding State
- **Status:** Seeder implemented in both Dart and JS.
- **Seeded Collections:** `users`, `addresses`, `categories`, `products`, `reviews`, `carts`, `orders`.
- **How to Seed:** 
  - Run the app and click the **'Seed Firebase'** button on the home screen.
  - Alternatively, use `node tools/wafi-seed.js` (requires service account key).

## 📍 Current Development Status (as of 2026-04-23)
- Firebase is fully configured.
- Firestore seeding logic is complete.
- Basic app structure with a placeholder Home Page containing the seeder button.

## 📝 Instructions for AI Agents
1. **Context First:** Always check this file before starting a task.
2. **Update After Changes:** If you implement a new feature, add a new component, or change the architecture, update the **"Current Development Status"** and **"Key Directories"** sections.
3. **Preserve Seeding Logic:** Do not remove the `WafiSeeder` until the production data is finalized.

---
*Last Updated: 2026-04-23 by Antigravity*
