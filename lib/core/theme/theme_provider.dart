import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';


enum AppThemeMode {
  system,
  light,
  dark;

  String get label => switch (this) {
    AppThemeMode.system => 'System Default',
    AppThemeMode.light  => 'Light Mode',
    AppThemeMode.dark   => 'Dark Mode',
  };

  String get storageKey => name;

  static AppThemeMode fromString(String? value) {
    return AppThemeMode.values.firstWhere(
          (e) => e.name == value,
      orElse: () => AppThemeMode.system,
    );
  }
}


class ThemeState {
  const ThemeState({
    required this.mode,
    required this.resolvedBrightness,
  });

  final AppThemeMode mode;
  final Brightness    resolvedBrightness;

  bool get isDark => resolvedBrightness == Brightness.dark;

  ThemeData get themeData => isDark ? AppTheme.dark : AppTheme.light;

  ThemeState copyWith({AppThemeMode? mode, Brightness? resolvedBrightness}) {
    return ThemeState(
      mode:               mode               ?? this.mode,
      resolvedBrightness: resolvedBrightness ?? this.resolvedBrightness,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ThemeState &&
          other.mode == mode &&
          other.resolvedBrightness == resolvedBrightness;

  @override
  int get hashCode => Object.hash(mode, resolvedBrightness);
}


class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(_initialState()) {
    _init();
  }

  static const _prefKey = 'wafi_theme_mode';

  static ThemeState _initialState() {
    final systemBrightness = SchedulerBinding
        .instance.platformDispatcher.platformBrightness;
    return ThemeState(
      mode:               AppThemeMode.system,
      resolvedBrightness: systemBrightness,
    );
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = AppThemeMode.fromString(prefs.getString(_prefKey));

    final systemBrightness = SchedulerBinding
        .instance.platformDispatcher.platformBrightness;

    final resolved = _resolve(saved, systemBrightness);

    state = ThemeState(mode: saved, resolvedBrightness: resolved);

    SchedulerBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        _onSystemBrightnessChanged;
  }

  void _onSystemBrightnessChanged() {
    if (state.mode != AppThemeMode.system) return;

    final systemBrightness = SchedulerBinding
        .instance.platformDispatcher.platformBrightness;

    state = state.copyWith(
      resolvedBrightness: systemBrightness,
    );
  }

  Future<void> setTheme(AppThemeMode mode) async {
    final systemBrightness = SchedulerBinding
        .instance.platformDispatcher.platformBrightness;

    final resolved = _resolve(mode, systemBrightness);

    state = ThemeState(mode: mode, resolvedBrightness: resolved);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode.storageKey);
  }

  Future<void> toggle() async {
    await setTheme(state.isDark ? AppThemeMode.light : AppThemeMode.dark);
  }

  static Brightness _resolve(AppThemeMode mode, Brightness system) {
    return switch (mode) {
      AppThemeMode.dark   => Brightness.dark,
      AppThemeMode.light  => Brightness.light,
      AppThemeMode.system => system,
    };
  }

  @override
  void dispose() {
    SchedulerBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
    null;
    super.dispose();
  }
}


final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

final themeDataProvider = Provider<ThemeData>((ref) {
  return ref.watch(themeProvider).themeData;
});

final isDarkProvider = Provider<bool>((ref) {
  return ref.watch(themeProvider).isDark;
});

final themeModeProvider = Provider<AppThemeMode>((ref) {
  return ref.watch(themeProvider).mode;
});