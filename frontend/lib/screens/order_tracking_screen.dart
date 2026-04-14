import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/order_models.dart';
import '../services/api_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key, required this.orderId});

  final int orderId;

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Timer? _poll;
  Timer? _sound;
  OrderModel? _order;

  @override
  void initState() {
    super.initState();
    _refresh();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _refresh(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _stopSound();
    super.dispose();
  }

  void _stopSound() {
    _sound?.cancel();
    _sound = null;
  }

  void _startSoundLoop() {
    _sound?.cancel();
    _sound = Timer.periodic(const Duration(seconds: 1), (_) {
      SystemSound.play(SystemSoundType.alert);
    });
  }

  Future<void> _refresh({bool silent = false}) async {
    final api = context.read<ApiService>();
    try {
      final o = await api.getOrder(widget.orderId);
      if (!mounted) return;
      final wasReady = _order?.isReady ?? false;
      setState(() => _order = o);
      if (o.isReady && !wasReady) {
        _startSoundLoop();
      }
      if (!o.isReady) {
        _stopSound();
      }
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _confirmPickup() async {
    final api = context.read<ApiService>();
    try {
      await api.confirmDelivery(widget.orderId);
      _stopSound();
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enjoy your meal!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _cancelBuyer() async {
    final api = context.read<ApiService>();
    try {
      await api.cancelOrder(widget.orderId);
      _stopSound();
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = _order;
    return Scaffold(
      appBar: AppBar(title: Text('Order #${widget.orderId}')),
      body: o == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (o.isReady)
                  MaterialBanner(
                    content: const Text('Your order is ready for pickup. Confirm when you have it.'),
                    actions: [
                      TextButton(onPressed: _confirmPickup, child: const Text('I picked it up')),
                    ],
                  ),
                ListTile(
                  title: const Text('Status'),
                  trailing: Text(o.status, style: Theme.of(context).textTheme.titleMedium),
                ),
                ListTile(
                  title: const Text('Deadline'),
                  subtitle: Text(DateFormat.yMMMd().add_jm().format(o.deadlineTime)),
                ),
                ListTile(
                  title: const Text('Pickup'),
                  subtitle: Text(o.deliveryLocationName ?? '—'),
                ),
                const Divider(),
                ...o.items.map(
                  (i) => ListTile(
                    title: Text(i.foodName ?? 'Item ${i.foodItemId}'),
                    trailing: Text('× ${i.quantity}'),
                  ),
                ),
                const SizedBox(height: 16),
                if (o.status != 'delivered' && o.status != 'cancelled') ...[
                  OutlinedButton(
                    onPressed: _cancelBuyer,
                    child: const Text('Cancel order (before deadline)'),
                  ),
                ],
              ],
            ),
    );
  }
}
