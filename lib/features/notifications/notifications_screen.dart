import 'package:flutter/material.dart';
import 'package:wafi_ecommerce_app/core/constants/sizes.dart';
import 'package:wafi_ecommerce_app/core/constants/strings.dart';
import 'package:wafi_ecommerce_app/shared/widgets/glass_card.dart';
import 'package:wafi_ecommerce_app/shared/widgets/wafi_app_bar.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_NotificationItem>[
      const _NotificationItem(
        title: 'Order confirmed',
        message: 'Your recent order was confirmed and is now being prepared.',
        icon: Icons.inventory_2_outlined,
      ),
      const _NotificationItem(
        title: 'Delivery update',
        message:
            'Track your rider and stay ready for today\'s delivery window.',
        icon: Icons.local_shipping_outlined,
      ),
      const _NotificationItem(
        title: 'Fresh arrivals',
        message: 'New grocery picks were added to the home feed for this week.',
        icon: Icons.local_offer_outlined,
      ),
    ];

    return Scaffold(
      appBar: const WafiAppBar(
        title: AppStrings.notifications,
        subtitle: 'Order updates, delivery alerts, and app activity',
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPaddingH,
          AppSizes.screenPaddingH,
          AppSizes.screenPaddingH,
          100,
        ),
        itemCount: items.length + 1,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSizes.md),
        itemBuilder: (context, index) {
          if (index == 0) {
            return GlassCard(
              variant: GlassCardVariant.elevated,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stay updated',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    'Notification data is not connected yet, so this screen '
                    'shows the customer-facing layout and placeholder updates.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          final item = items[index - 1];
          return GlassCard(
            variant: GlassCardVariant.elevated,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Icon(
                    item.icon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Text(
                        item.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;
}
