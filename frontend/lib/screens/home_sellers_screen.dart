import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/seller_summary.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';
import 'seller_menu_screen.dart';

class HomeSellersScreen extends StatelessWidget {
  const HomeSellersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uni = context.watch<AppState>().university ?? '';
    final api = context.read<ApiService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus kitchens'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: Text(uni, style: Theme.of(context).textTheme.labelMedium)),
          ),
        ],
      ),
      body: FutureBuilder<List<SellerSummary>>(
        key: ValueKey(uni),
        future: api.listSellers(uni),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Could not load sellers\n${snap.error}'));
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('No approved sellers on this campus yet.'));
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final s = list[i];
              return ListTile(
                title: Text(s.kitchenName),
                subtitle: Text(s.description ?? ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.read<AppState>().openSeller(s);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SellerMenuScreen()));
                },
              );
            },
          );
        },
      ),
    );
  }
}
