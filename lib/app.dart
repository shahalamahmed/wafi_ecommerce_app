import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/theme/app_theme.dart';
import 'package:wafi_ecommerce_app/core/theme/responsive_text_scale.dart';
import 'package:wafi_ecommerce_app/core/theme/theme_provider.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_model.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_provider.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_screen.dart';
import 'package:wafi_ecommerce_app/shared/layout/main_layout.dart';

class WafiApp extends ConsumerWidget {
  const WafiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);

    final showMainLayout =
        authState.status == AuthStatus.authenticated ||
        authState.status == AuthStatus.anonymous;

    final showBootSplash =
        authState.status == AuthStatus.loading ||
        authState.status == AuthStatus.initial;
    final themeMode = switch (themeState.mode) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };

    return MaterialApp(
      title: 'Wafi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final scaleFactor = ResponsiveTextScale.factorForWidth(
          mediaQuery.size.width,
        );
        final activeTheme = Theme.of(context).brightness == Brightness.dark
            ? AppTheme.dark
            : AppTheme.light;

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: Theme(
            data: ResponsiveTextScale.apply(activeTheme, scaleFactor),
            child: child!,
          ),
        );
      },

      home: showMainLayout
          ? const MainLayout()
          : showBootSplash
          ? const _BootSplash()
          : const AuthScreen(),
    );
  }
}

class _BootSplash extends StatelessWidget {
  const _BootSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
