import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/delivery_location.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';

class CartCheckoutScreen extends StatefulWidget {
  const CartCheckoutScreen({super.key});

  @override
  State<CartCheckoutScreen> createState() => _CartCheckoutScreenState();
}

class _CartCheckoutScreenState extends State<CartCheckoutScreen> {
  DeliveryLocation? _loc;
  late DateTime _deadline;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _deadline = DateTime(now.year, now.month, now.day, 18, 0);
    if (_deadline.isBefore(now)) {
      _deadline = now.add(const Duration(hours: 2));
    }
  }

  Future<void> _pickDeadline() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 14)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_deadline));
    if (t == null || !mounted) return;
    setState(() {
      _deadline = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  Future<void> _submit() async {
    final app = context.read<AppState>();
    final api = context.read<ApiService>();
    final seller = app.browsingSeller;
    if (seller == null || _loc == null || app.cart.isEmpty) return;
    setState(() => _busy = true);
    try {
      final items = app.cart.values
          .map((c) => {'food_item_id': c.item.id, 'quantity': c.quantity})
          .toList();
      await api.createOrder(
        sellerId: seller.sellerId,
        deliveryLocationId: _loc!.id,
        deadline: _deadline.toUtc(),
        items: items,
      );
      app.clearCart();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed')));
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final seller = app.browsingSeller;
    final api = context.read<ApiService>();
    if (seller == null) {
      return const Scaffold(body: Center(child: Text('No seller')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Cart & checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...app.cart.values.map(
            (c) => ListTile(
              title: Text(c.item.name),
              subtitle: Text('${c.quantity} × \$${c.item.price.toStringAsFixed(2)}'),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Total'),
            trailing: Text('\$${app.cartTotal().toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Batch deadline'),
            subtitle: Text(DateFormat.yMMMd().add_jm().format(_deadline)),
            trailing: IconButton(icon: const Icon(Icons.schedule), onPressed: _pickDeadline),
          ),
          const Text('Delivery spot', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          FutureBuilder<List<DeliveryLocation>>(
            future: api.listDelivery(seller.sellerId, approvedOnly: true),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
              }
              final locs = snap.data!;
              if (locs.isEmpty) {
                return const Text('This seller has no approved pickup spots yet.');
              }
              return Column(
                children: locs
                    .map(
                      (l) => RadioListTile<DeliveryLocation>(
                        value: l,
                        groupValue: _loc,
                        title: Text(l.name),
                        onChanged: (v) => setState(() => _loc = v),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: (_busy || app.cart.isEmpty || _loc == null) ? null : _submit,
            child: _busy ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Place order'),
          ),
        ],
      ),
    );
  }
}
