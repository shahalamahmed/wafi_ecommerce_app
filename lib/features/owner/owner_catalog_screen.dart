import 'package:flutter/material.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/features/owner/category_management_screen.dart';
import 'package:wafi_ecommerce_app/features/owner/product_management_screen.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';

class OwnerCatalogScreen extends StatelessWidget {
  const OwnerCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.screenPaddingH,
              AppSizes.md,
              AppSizes.screenPaddingH,
              0,
            ),
            child: GlassCard(
              variant: GlassCardVariant.elevated,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Catalog Workspace',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    'Manage categories and products from the same owner workspace.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSizes.lg),
                  TabBar(
                    tabs: const [
                      Tab(text: 'Categories'),
                      Tab(text: 'Products'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          const Expanded(
            child: TabBarView(
              children: [
                CategoryManagementScreen(),
                ProductManagementScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
