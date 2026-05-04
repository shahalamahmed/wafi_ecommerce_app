import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/features/test_order/test_order_provider.dart';
import 'package:wafi_ecommerce_app/shared/widgets/wafi_app_bar.dart';

class TestOrderScreen extends ConsumerStatefulWidget {
  const TestOrderScreen({super.key});

  @override
  ConsumerState<TestOrderScreen> createState() => _TestOrderScreenState();
}

class _TestOrderScreenState extends ConsumerState<TestOrderScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(testOrderProvider.notifier).loadOrders());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(testOrderProvider);
    return Scaffold(
      appBar: WafiAppBar(title: "Test Order"),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.hasError
          ? Center(child: Text(state.errorMessage!))
          : ListView.builder(
              itemCount: state.orders.length,
              itemBuilder: (context, index) {
                final order = state.orders[index];
                return Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: Text(order.orderId),
                        subtitle: Text('Amount: ${order.amount}'),
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: Text(order.orderId),
                        subtitle: Text('Amount: ${order.productId}'),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
