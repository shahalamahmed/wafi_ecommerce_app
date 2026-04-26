import 'package:flutter/foundation.dart';

/// App-side seeding is intentionally disabled for production safety.
/// Use `tools/wafi-seed.js` for controlled environment seeding instead.
abstract final class WafiSeeder {
  static Future<void> seed() async {
    if (kReleaseMode) {
      throw UnsupportedError(
        'WafiSeeder is disabled in release builds. Use the Node seeder in tools/.',
      );
    }

    throw UnsupportedError(
      'WafiSeeder is disabled. Use tools/wafi-seed.js to seed Firestore/Auth safely.',
    );
  }
}
