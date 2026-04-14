import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/delivery_location.dart';
import '../services/api_service.dart';

class SellerLocationsTab extends StatefulWidget {
  const SellerLocationsTab({super.key});

  @override
  State<SellerLocationsTab> createState() => _SellerLocationsTabState();
}

class _SellerLocationsTabState extends State<SellerLocationsTab> {
  final _name = TextEditingController();
  int? _sellerId;
  int _tick = 0;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _resolveSeller() async {
    final api = context.read<ApiService>();
    final me = await api.me();
    final sellers = await api.listSellers(me.university);
    final mine = sellers.firstWhere((s) => s.userId == me.id);
    if (mounted) setState(() => _sellerId = mine.sellerId);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveSeller());
  }

  Future<void> _add() async {
    if (_name.text.trim().isEmpty) return;
    try {
      await context.read<ApiService>().createDelivery(name: _name.text.trim());
      _name.clear();
      setState(() => _tick++);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location created — pending admin approval')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sid = _sellerId;
    if (sid == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final api = context.read<ApiService>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Pickup spots', style: Theme.of(context).textTheme.titleMedium),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Place name (e.g. Library steps)')),
        FilledButton(onPressed: _add, child: const Text('Request new spot')),
        const SizedBox(height: 16),
        FutureBuilder<List<DeliveryLocation>>(
          key: ValueKey(_tick),
          future: api.listDelivery(sid, approvedOnly: false),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final locs = snap.data!;
            if (locs.isEmpty) {
              return const Text('No locations yet.');
            }
            return Column(
              children: locs
                  .map(
                    (l) => ListTile(
                      title: Text(l.name),
                      subtitle: Text(l.isApproved ? 'Approved' : 'Pending approval'),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
