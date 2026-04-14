import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../state/app_state.dart';

class SellerRequestScreen extends StatefulWidget {
  const SellerRequestScreen({super.key});

  @override
  State<SellerRequestScreen> createState() => _SellerRequestScreenState();
}

class _SellerRequestScreenState extends State<SellerRequestScreen> {
  final _kitchen = TextEditingController();
  final _desc = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _kitchen.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final api = context.read<ApiService>();
      final app = context.read<AppState>();
      await api.sellerRequest(kitchenName: _kitchen.text.trim(), description: _desc.text.trim());
      await app.refreshUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted. Wait for admin approval.')),
      );
      Navigator.of(context).pop();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Seller request')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _kitchen, decoration: const InputDecoration(labelText: 'Kitchen name')),
          const SizedBox(height: 12),
          TextField(controller: _desc, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
