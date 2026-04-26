import 'package:wafi_ecommerce_app/core/constants/strings.dart';

abstract final class AppValidators {
  static String? required(String? value, {String? message}) {
    if (value == null || value.trim().isEmpty) {
      return message ?? AppStrings.validRequired;
    }
    return null;
  }

  static String? email(String? value) {
    final empty = required(value);
    if (empty != null) return empty;

    final email = value!.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return AppStrings.validEmail;
    }
    return null;
  }

  static String? password(String? value) {
    final empty = required(value);
    if (empty != null) return empty;

    if (value!.trim().length < 8) {
      return AppStrings.validPassword;
    }
    return null;
  }

  static String? phone(String? value) {
    final empty = required(value);
    if (empty != null) return empty;

    final digits = value!.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 11) {
      return AppStrings.validPhone;
    }
    return null;
  }

  static String? name(String? value) {
    final empty = required(value);
    if (empty != null) return empty;

    if (value!.trim().length < 2) {
      return AppStrings.validName;
    }
    return null;
  }

  static String? confirmPassword(String? password, String? confirmPassword) {
    final empty = required(confirmPassword);
    if (empty != null) return empty;

    if (password != confirmPassword) {
      return AppStrings.validPassMatch;
    }
    return null;
  }
}
