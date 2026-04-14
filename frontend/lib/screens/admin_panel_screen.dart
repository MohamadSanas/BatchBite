import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _tick = 0;

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiService>();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sellers'),
              Tab(text: 'Locations'),
              Tab(text: 'Reports'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FutureBuilder<List<dynamic>>(
              key: ValueKey(_tick),
              future: api.adminSellerRequests(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rows = snap.data!;
                if (rows.isEmpty) {
                  return const Center(child: Text('No pending seller requests.'));
                }
                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final r = rows[i] as Map<String, dynamic>;
                    final u = r['user'] as Map<String, dynamic>;
                    final uid = u['id'] as int;
                    final name = u['name'] as String;
                    return ListTile(
                      title: Text(name),
                      subtitle: Text(u['email'] as String),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline),
                            onPressed: () async {
                              await api.adminApproveSeller(uid, true);
                              setState(() => _tick++);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined),
                            onPressed: () async {
                              await api.adminApproveSeller(uid, false);
                              setState(() => _tick++);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            FutureBuilder<List<dynamic>>(
              key: ValueKey('loc$_tick'),
              future: api.adminPendingLocations(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rows = snap.data!;
                if (rows.isEmpty) {
                  return const Center(child: Text('No pending delivery spots.'));
                }
                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final r = rows[i] as Map<String, dynamic>;
                    final id = r['id'] as int;
                    return ListTile(
                      title: Text(r['name'] as String),
                      subtitle: Text('Seller ${r['seller_id']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: () async {
                          await api.adminApproveLocation(id, true);
                          setState(() => _tick++);
                        },
                      ),
                    );
                  },
                );
              },
            ),
            FutureBuilder<Map<String, dynamic>>(
              future: api.adminTxSummary(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final m = snap.data!;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Platform transactions', style: Theme.of(context).textTheme.titleMedium),
                    ListTile(title: const Text('Count'), trailing: Text('${m['transaction_count']}')),
                    ListTile(title: const Text('Volume'), trailing: Text('${m['total_amount']}')),
                    ListTile(title: const Text('Recorded profit'), trailing: Text('${m['profit']}')),
                    const SizedBox(height: 12),
                    Text(
                      'PDF exports: GET /reports/pdf/daily and /reports/pdf/monthly (seller auth) · /reports/pdf/order/{id}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
