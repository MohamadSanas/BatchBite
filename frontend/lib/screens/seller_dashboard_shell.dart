import 'package:flutter/material.dart';

import 'seller_kitchen_tab.dart';
import 'seller_locations_tab.dart';
import 'seller_orders_tab.dart';

class SellerDashboardShell extends StatefulWidget {
  const SellerDashboardShell({super.key});

  @override
  State<SellerDashboardShell> createState() => _SellerDashboardShellState();
}

class _SellerDashboardShellState extends State<SellerDashboardShell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      SellerKitchenTab(),
      SellerOrdersTab(),
      SellerLocationsTab(),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Seller')),
      body: pages[_i],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.kitchen_outlined), selectedIcon: Icon(Icons.kitchen), label: 'Kitchen'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.place_outlined), selectedIcon: Icon(Icons.place), label: 'Spots'),
        ],
      ),
    );
  }
}
