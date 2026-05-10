import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/core/constants/colors.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_provider.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_screen.dart';
import 'package:wafi_ecommerce_app/features/cart/cart_model.dart';
import 'package:wafi_ecommerce_app/features/cart/cart_provider.dart';
import 'package:wafi_ecommerce_app/features/orders/checkout_screen.dart';
import 'package:wafi_ecommerce_app/features/products/product_screen.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_button.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/wafi_app_bar.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key, this.immersiveShell = false});

  final bool immersiveShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);
    final topInset = immersiveShell
        ? WafiAppBar.compactOverlayTopInset(
            context,
            hasSubtitle: false,
            revealAmount: AppSizes.xl5,
          )
        : AppSizes.lg;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.isEmpty) {
      return _CartEmptyState(
        onContinue: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ProductCatalogPage(
                title: 'All Products',
                subtitle: 'Browse products and add items to your cart',
              ),
            ),
          );
        },
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: notifier.load,
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                AppSizes.screenPaddingH,
                topInset,
                AppSizes.screenPaddingH,
                100,
              ),
              itemCount: state.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
              itemBuilder: (context, index) {
                final item = state.items[index];

                return _CartRow(
                  item: item,
                  onIncrement: () => notifier.increment(item.id),
                  onDecrement: () => notifier.decrement(item.id),
                  onRemove: () => notifier.remove(item.id),
                );
              },
            ),
          ),
        ),
        _CartSummary(state: state),
        const SizedBox(height: 100),
      ],
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      variant: GlassCardVariant.elevated,
      padding: const EdgeInsets.all(AppSizes.md),
      child: Row(
        children: [
          _CartImage(imageUrl: item.imageUrl, productName: item.productName),

          const SizedBox(width: AppSizes.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                if (item.selectedOptionLabel.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    item.selectedOptionLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],

                const SizedBox(height: AppSizes.sm),

                Text(
                  '${AppStrings.currencySymbol}${item.unitPrice.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),

                const SizedBox(height: AppSizes.sm),

                _QuantityStepper(
                  quantity: item.quantity,
                  onIncrement: onIncrement,
                  onDecrement: onDecrement,
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSizes.sm),

          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _CartImage extends StatelessWidget {
  const _CartImage({required this.imageUrl, required this.productName});

  final String imageUrl;
  final String productName;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        color: isDark
            ? AppColors.glassElevatedDark
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.trim().isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _CartImageFallback(name: productName),
            )
          : _CartImageFallback(name: productName),
    );
  }
}

class _CartImageFallback extends StatelessWidget {
  const _CartImageFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xs),
        child: Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.xs,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(icon: Icons.remove_rounded, onTap: onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
            child: Text(
              '$quantity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          _StepperButton(icon: Icons.add_rounded, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        child: Icon(icon, size: AppSizes.iconSm, color: Colors.white),
      ),
    );
  }
}

class _CartSummary extends ConsumerWidget {
  const _CartSummary({required this.state});

  final CartState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? const Color(0xFF1A1C1F)
        : Theme.of(context).colorScheme.surface.withValues(alpha: 0.95);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.screenPaddingH),
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SummaryRow(
              label: AppStrings.subtotal,
              value:
                  '${AppStrings.currencySymbol}${state.subtotal.toStringAsFixed(0)}',
            ),
            const SizedBox(height: AppSizes.xs),
            _SummaryRow(
              label: AppStrings.tax,
              value:
                  '${AppStrings.currencySymbol}${state.tax.toStringAsFixed(0)}',
            ),
            const Divider(height: AppSizes.lg),
            _SummaryRow(
              label: AppStrings.total,
              value:
                  '${AppStrings.currencySymbol}${state.total.toStringAsFixed(0)}',
              isTotal: true,
            ),
            const SizedBox(height: AppSizes.md),
            GlassButton(
              label: 'Proceed',
              isFullWidth: true,
              onPressed: () async {
                if (!authState.isAuthenticated) {
                  final didLogin = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => const AuthScreen(closeOnSuccess: true),
                    ),
                  );
                  if (!context.mounted || didLogin != true) return;
                }

                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CheckoutScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final style = isTotal
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyMedium;

    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text(
          value,
          style: style?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CartEmptyState extends StatelessWidget {
  const _CartEmptyState({required this.onContinue});

  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.screenPaddingH),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: GlassCard(
            variant: GlassCardVariant.elevated,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: AppSizes.iconXl,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  AppStrings.cartEmpty,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  AppStrings.cartEmptySub,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSizes.lg),
                GlassButton(
                  label: AppStrings.continueShopping,
                  isFullWidth: false,
                  onPressed: () => ProductScreen(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
