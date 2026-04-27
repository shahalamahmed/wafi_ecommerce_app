import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  const SettingsState({
    required this.notificationsEnabled,
    required this.marketingEnabled,
    required this.languageCode,
    required this.isLoading,
  });

  const SettingsState.initial()
      : notificationsEnabled = true,
        marketingEnabled = false,
        languageCode = 'en',
        isLoading = true;

  final bool notificationsEnabled;
  final bool marketingEnabled;
  final String languageCode;
  final bool isLoading;

  String get languageLabel => switch (languageCode) {
        'bn' => 'Bangla',
        _ => 'English',
      };

  SettingsState copyWith({
    bool? notificationsEnabled,
    bool? marketingEnabled,
    String? languageCode,
    bool? isLoading,
  }) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      marketingEnabled: marketingEnabled ?? this.marketingEnabled,
      languageCode: languageCode ?? this.languageCode,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState.initial()) {
    _load();
  }

  static const _notificationsKey = 'wafi_notifications_enabled';
  static const _marketingKey = 'wafi_marketing_enabled';
  static const _languageKey = 'wafi_language_code';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      notificationsEnabled: prefs.getBool(_notificationsKey) ?? true,
      marketingEnabled: prefs.getBool(_marketingKey) ?? false,
      languageCode: prefs.getString(_languageKey) ?? 'en',
      isLoading: false,
    );
  }

  Future<void> setNotificationsEnabled(bool value) async {
    state = state.copyWith(notificationsEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
  }

  Future<void> setMarketingEnabled(bool value) async {
    state = state.copyWith(marketingEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_marketingKey, value);
  }

  Future<void> setLanguageCode(String code) async {
    state = state.copyWith(languageCode: code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, code);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
