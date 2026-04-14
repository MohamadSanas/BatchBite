import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order_models.dart';
import '../services/api_service.dart';

class SellerOrdersTab extends StatefulWidget {
  const SellerOrdersTab({super.key});

  @override
  State<SellerOrdersTab> createState() => _SellerOrdersTabState();
}

class _SellerOrdersTabState extends State<SellerOrdersTab> {
  int _tick = 0;

  Future<void> _reload() async => setState(() => _tick++);

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiService>();
    return Column(
      children: [
        ListTile(
          title: const Text('Active batch summary'),
          subtitle: FutureBuilder<Map<String, dynamic>>(
            key: ValueKey(_tick),
            future: api.ordersSummary(),
            builder: (context, s) {
              if (s.connectionState != ConnectionState.done) {
                return const Text('Loading…');
              }
              if (s.hasError) {
                return Text('${s.error}');
              }
              final groups = (s.data!['groups'] as List<dynamic>? ?? []);
              if (groups.isEmpty) {
                return const Text('No active grouped demand.');
              }
              return Text('${groups.length} pickup location(s) with open orders');
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: FutureBuilder<List<OrderModel>>(
            key: ValueKey(_tick),
            future: api.sellerOrders(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = snap.data!;
              if (list.isEmpty) {
                return const Center(child: Text('No orders yet.'));
              }
              return ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final o = list[i];
                  return ExpansionTile(
                    title: Text('Order #${o.id} · ${o.status}'),
                    subtitle: Text(o.deliveryLocationName ?? ''),
                    children: [
                      ...o.items.map(
                        (it) => ListTile(
                          dense: true,
                          title: Text(it.foodName ?? 'Item'),
                          trailing: Text('× ${it.quantity}'),
                        ),
                      ),
                      ButtonBar(
                        children: [
                          TextButton(
                            onPressed: o.status == 'delivered' || o.status == 'cancelled'
                                ? null
                                : () async {
                                    try {
                                      await api.updateOrderStatus(o.id, 'preparing');
                                      await _reload();
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                                      }
                                    }
                                  },
                            child: const Text('Preparing'),
                          ),
                          TextButton(
                            onPressed: o.status == 'delivered' || o.status == 'cancelled'
                                ? null
                                : () async {
                                    try {
                                      await api.updateOrderStatus(o.id, 'ready');
                                      await _reload();
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                                      }
                                    }
                                  },
                            child: const Text('Ready'),
                          ),
                          TextButton(
                            onPressed: o.status == 'delivered' || o.status == 'cancelled'
                                ? null
                                : () async {
                                    final reason = await showDialog<String>(
                                      context: context,
                                      builder: (c) {
                                        final t = TextEditingController();
                                        return AlertDialog(
                                          title: const Text('Cancel reason'),
                                          content: TextField(
                                            controller: t,
                                            decoration: const InputDecoration(hintText: 'Reason'),
                                          ),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Back')),
                                            FilledButton(
                                              onPressed: () => Navigator.pop(c, t.text),
                                              child: const Text('Cancel order'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    if (reason == null || reason.isEmpty) return;
                                    try {
                                      await api.updateOrderStatus(o.id, 'cancelled', reason: reason);
                                      await _reload();
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                                      }
                                    }
                                  },
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
