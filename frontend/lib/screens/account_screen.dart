import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'admin_panel_screen.dart';
import 'auth_screen.dart';
import 'seller_dashboard_shell.dart';
import 'seller_request_screen.dart';
import 'university_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final u = app.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        children: [
          if (u != null) ...[
            ListTile(title: Text(u.name), subtitle: Text(u.email)),
            ListTile(title: const Text('Campus'), subtitle: Text(app.university ?? '—')),
            ListTile(title: const Text('Role'), subtitle: Text(u.role)),
          ],
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text('Change university'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UniversityScreen())),
          ),
          if (u != null && !u.isSeller && !u.isAdmin)
            ListTile(
              leading: const Icon(Icons.store_outlined),
              title: const Text('Become a seller'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SellerRequestScreen())),
            ),
          if (u != null && u.isSeller)
            ListTile(
              leading: const Icon(Icons.dashboard_customize_outlined),
              title: const Text('Seller dashboard'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SellerDashboardShell())),
            ),
          if (u != null && u.isAdmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Admin panel'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminPanelScreen())),
            ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () async {
              await app.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
