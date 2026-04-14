import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/food_item.dart';
import '../services/api_service.dart';

class SellerKitchenTab extends StatefulWidget {
  const SellerKitchenTab({super.key});

  @override
  State<SellerKitchenTab> createState() => _SellerKitchenTabState();
}

class _SellerKitchenTabState extends State<SellerKitchenTab> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _kitchenName = TextEditingController();
  final _kitchenDesc = TextEditingController();
  int? _sellerId;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _kitchenName.dispose();
    _kitchenDesc.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final api = context.read<ApiService>();
    final me = await api.me();
    if (!mounted) return;
    setState(() => _sellerId = null);
    try {
      final sellers = await api.listSellers(me.university);
      final mine = sellers.firstWhere((s) => s.userId == me.id);
      setState(() => _sellerId = mine.sellerId);
      _kitchenName.text = mine.kitchenName;
      _kitchenDesc.text = mine.description ?? '';
    } catch (_) {
      setState(() => _sellerId = -1);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _saveProfile() async {
    try {
      await context.read<ApiService>().updateKitchen(
        kitchenName: _kitchenName.text.trim().isEmpty ? null : _kitchenName.text.trim(),
        description: _kitchenDesc.text.trim().isEmpty ? null : _kitchenDesc.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kitchen updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _addItem() async {
    final price = double.tryParse(_price.text);
    if (price == null || price <= 0) return;
    try {
      await context.read<ApiService>().createFood(name: _name.text.trim(), price: price);
      _name.clear();
      _price.clear();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item added')));
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
    if (sid < 0) {
      return const Center(child: Text('Could not resolve your seller profile.'));
    }
    final api = context.read<ApiService>();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('My kitchen', style: Theme.of(context).textTheme.titleMedium),
          TextField(controller: _kitchenName, decoration: const InputDecoration(labelText: 'Kitchen name')),
          TextField(controller: _kitchenDesc, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: _saveProfile, child: const Text('Save profile')),
          ),
          const Divider(),
          Text('Add menu item', style: Theme.of(context).textTheme.titleMedium),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: _price, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
          FilledButton(onPressed: _addItem, child: const Text('Add item')),
          const SizedBox(height: 16),
          Text('Menu', style: Theme.of(context).textTheme.titleMedium),
          FutureBuilder<List<FoodItem>>(
            key: ValueKey(sid),
            future: api.listFood(sid),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snap.data!;
              if (items.isEmpty) {
                return const Text('No items yet.');
              }
              return Column(
                children: items
                    .map((f) => ListTile(title: Text(f.name), subtitle: Text('\$${f.price.toStringAsFixed(2)} · ${f.available ? "available" : "off"}')))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
