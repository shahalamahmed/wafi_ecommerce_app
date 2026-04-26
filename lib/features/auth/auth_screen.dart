import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_model.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_provider.dart';
import 'package:wafi_ecommerce_app/features/auth/widgets/login_form.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_chip.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF000000), Color(0xFF080808), Color(0xFF000000)]
                : const [Color(0xFFFFFFFF), Color(0xFFF5F5F5), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const _AuthBackdrop(),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.screenPaddingH),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: GlassCard(
                      variant: GlassCardVariant.elevated,
                      padding: const EdgeInsets.all(AppSizes.xl3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            AppStrings.appName,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: AppSizes.sm),
                          Text(
                            AppStrings.appTagline,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSizes.xl2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GlassChip(
                                label: AppStrings.login,
                                isSelected: authState.view == AuthView.login,
                                onTap: () => authNotifier.setView(AuthView.login),
                              ),
                              const SizedBox(width: AppSizes.sm),
                              GlassChip(
                                label: AppStrings.signup,
                                isSelected: authState.view == AuthView.register,
                                onTap: () => authNotifier.setView(AuthView.register),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.xl2),
                          Text(
                            authState.view == AuthView.login
                                ? AppStrings.welcomeBack
                                : AppStrings.createAccount,
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSizes.md),
                          if (authState.hasError) ...[
                            _AuthErrorBanner(message: authState.errorMessage!),
                            const SizedBox(height: AppSizes.lg),
                          ],
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: AppSizes.animNormal),
                            child: authState.view == AuthView.login
                                ? LoginForm(
                                    key: const ValueKey('login_form'),
                                    isLoading: authState.isLoading,
                                    onSubmit: authNotifier.login,
                                    onGoogleSignIn: authNotifier.signInWithGoogle,
                                    onGuestMode: authNotifier.continueAsGuest,
                                    onForgotPassword: (email) async {
                                      if (email.trim().isEmpty) {
                                        authNotifier.clearError();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Enter your email first to reset password.'),
                                          ),
                                        );
                                        return;
                                      }

                                      await authNotifier.sendPasswordResetEmail(email);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(AppStrings.resetSent),
                                        ),
                                      );
                                    },
                                  )
                                : RegistrationForm(
                                    key: const ValueKey('register_form'),
                                    isLoading: authState.isLoading,
                                    onSubmit: authNotifier.register,
                                  ),
                          ),
                          const SizedBox(height: AppSizes.lg),
                          Text(
                            authState.view == AuthView.login
                                ? AppStrings.dontHaveAcc
                                : AppStrings.alreadyHaveAcc,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -60,
            left: -20,
            child: _GlowOrb(
              size: 220,
              color: isDark ? Colors.white10 : Colors.black12,
            ),
          ),
          Positioned(
            bottom: -80,
            right: -40,
            child: _GlowOrb(
              size: 260,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

class _AuthErrorBanner extends StatelessWidget {
  const _AuthErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.md,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
