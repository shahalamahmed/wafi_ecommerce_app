import 'package:flutter_test/flutter_test.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';

void main() {
  test('app name stays stable', () {
    expect(AppStrings.appName, 'Wafi');
  });
}
