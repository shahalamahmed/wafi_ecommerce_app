import 'package:flutter/material.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/core/utils/validators.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_model.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_button.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_input.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({
    super.key,
    required this.isLoading,
    required this.onSubmit,
    required this.onGoogleSignIn,
    required this.onGuestMode,
    required this.onForgotPassword,
  });

  final bool isLoading;
  final ValueChanged<LoginCredentials> onSubmit;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onGuestMode;
  final ValueChanged<String> onForgotPassword;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final Map<String, String?> _errors = {};
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final emailError = AppValidators.email(_emailController.text);
    final passwordError = AppValidators.password(_passwordController.text);

    setState(() {
      _errors['email'] = emailError;
      _errors['password'] = passwordError;
    });

    if (emailError != null || passwordError != null) return;

    widget.onSubmit(
      LoginCredentials(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassInput(
          controller: _emailController,
          label: AppStrings.email,
          isRequired: true,
          hint: AppStrings.emailHint,
          prefixIcon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          errorText: _errors['email'],
          onChanged: (_) {
            if (_errors['email'] != null) {
              setState(() => _errors['email'] = null);
            }
          },
        ),
        const SizedBox(height: AppSizes.lg),
        GlassInput(
          controller: _passwordController,
          label: AppStrings.password,
          isRequired: true,
          hint: AppStrings.passwordHint,
          prefixIcon: Icons.lock_outline_rounded,
          suffixIcon: _obscurePassword
              ? Icons.visibility_rounded
              : Icons.visibility_off_rounded,
          onSuffixTap: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          errorText: _errors['password'],
          onSubmitted: (_) => _submit(),
          onChanged: (_) {
            if (_errors['password'] != null) {
              setState(() => _errors['password'] = null);
            }
          },
        ),
        const SizedBox(height: AppSizes.md),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: widget.isLoading
                ? null
                : () => widget.onForgotPassword(_emailController.text.trim()),
            child: const Text(AppStrings.forgotPassword),
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        GlassButton(
          label: AppStrings.login,
          prefixIcon: Icons.login_rounded,
          isLoading: widget.isLoading,
          onPressed: widget.isLoading ? null : _submit,
        ),
        const SizedBox(height: AppSizes.lg),
        Row(
          children: [
            Expanded(child: Divider(color: Theme.of(context).dividerColor)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: Text(AppStrings.orContinueWith),
            ),
            Expanded(child: Divider(color: Theme.of(context).dividerColor)),
          ],
        ),
        const SizedBox(height: AppSizes.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AuthIconAction(
              tooltip: AppStrings.continueGoogle,
              icon: Icons.g_mobiledata_rounded,
              onTap: widget.isLoading ? null : widget.onGoogleSignIn,
            ),
            const SizedBox(width: AppSizes.md),
            _AuthIconAction(
              tooltip: AppStrings.continueGuest,
              icon: Icons.explore_outlined,
              onTap: widget.isLoading ? null : widget.onGuestMode,
            ),
          ],
        ),
      ],
    );
  }
}

class _AuthIconAction extends StatelessWidget {
  const _AuthIconAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    final color = Theme.of(context).colorScheme.primary;
    final child = GlassCard(
      variant: GlassCardVariant.elevated,
      width: 64,
      height: 64,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Icon(icon, size: 32, color: color),
    );

    return Tooltip(
      message: tooltip,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: AppSizes.animFast),
        opacity: isDisabled ? AppSizes.opacityDisabled : 1,
        child: isDisabled
            ? child
            : GlassTappableCard(
                onTap: onTap!,
                variant: GlassCardVariant.elevated,
                width: 64,
                height: 64,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                child: Icon(icon, size: 32, color: color),
              ),
      ),
    );
  }
}

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({
    super.key,
    required this.isLoading,
    required this.onSubmit,
  });

  final bool isLoading;
  final ValueChanged<RegistrationData> onSubmit;

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final Map<String, String?> _errors = {};
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    final nextErrors = <String, String?>{
      'firstName': AppValidators.name(_firstNameController.text),
      'lastName': AppValidators.name(_lastNameController.text),
      'phone': AppValidators.phone(_phoneController.text),
      'email': AppValidators.email(_emailController.text),
      'password': AppValidators.password(_passwordController.text),
      'confirmPassword': AppValidators.confirmPassword(
        _passwordController.text,
        _confirmPasswordController.text,
      ),
    };

    setState(
      () => _errors
        ..clear()
        ..addAll(nextErrors),
    );

    if (nextErrors.values.any((error) => error != null)) return;

    widget.onSubmit(
      RegistrationData(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: GlassInput(
                controller: _firstNameController,
                label: AppStrings.firstName,
                isRequired: true,
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                errorText: _errors['firstName'],
                onChanged: (_) => setState(() => _errors['firstName'] = null),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: GlassInput(
                controller: _lastNameController,
                label: AppStrings.lastName,
                isRequired: true,
                prefixIcon: Icons.badge_outlined,
                textInputAction: TextInputAction.next,
                errorText: _errors['lastName'],
                onChanged: (_) => setState(() => _errors['lastName'] = null),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.lg),
        GlassInput(
          controller: _phoneController,
          label: AppStrings.phone,
          isRequired: true,
          hint: AppStrings.phoneHint,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          errorText: _errors['phone'],
          onChanged: (_) => setState(() => _errors['phone'] = null),
        ),
        const SizedBox(height: AppSizes.lg),
        GlassInput(
          controller: _emailController,
          label: AppStrings.email,
          isRequired: true,
          hint: AppStrings.emailHint,
          prefixIcon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          errorText: _errors['email'],
          onChanged: (_) => setState(() => _errors['email'] = null),
        ),
        const SizedBox(height: AppSizes.lg),
        GlassInput(
          controller: _passwordController,
          label: AppStrings.password,
          isRequired: true,
          hint: AppStrings.passwordHint,
          prefixIcon: Icons.lock_outline_rounded,
          suffixIcon: _obscurePassword
              ? Icons.visibility_rounded
              : Icons.visibility_off_rounded,
          onSuffixTap: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          errorText: _errors['password'],
          onChanged: (_) => setState(() => _errors['password'] = null),
        ),
        const SizedBox(height: AppSizes.lg),
        GlassInput(
          controller: _confirmPasswordController,
          label: AppStrings.confirmPass,
          isRequired: true,
          hint: AppStrings.passwordHint,
          prefixIcon: Icons.verified_user_outlined,
          suffixIcon: _obscureConfirmPassword
              ? Icons.visibility_rounded
              : Icons.visibility_off_rounded,
          onSuffixTap: () {
            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
          },
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          errorText: _errors['confirmPassword'],
          onSubmitted: (_) => _submit(),
          onChanged: (_) => setState(() => _errors['confirmPassword'] = null),
        ),
        const SizedBox(height: AppSizes.xl2),
        GlassButton(
          label: AppStrings.signup,
          prefixIcon: Icons.person_add_alt_1_rounded,
          isLoading: widget.isLoading,
          onPressed: widget.isLoading ? null : _submit,
        ),
      ],
    );
  }
}
