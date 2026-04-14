import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/food_item.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';
import 'cart_checkout_screen.dart';

class SellerMenuScreen extends StatelessWidget {
  const SellerMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final seller = app.browsingSeller;
    final api = context.read<ApiService>();
    if (seller == null) {
      return const Scaffold(body: Center(child: Text('No seller selected')));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(seller.kitchenName),
        actions: [
          IconButton(
            icon: Builder(
              builder: (context) {
                final n = app.cart.values.fold<int>(0, (a, c) => a + c.quantity);
                if (n == 0) return const Icon(Icons.shopping_cart_outlined);
                return Badge(label: Text('$n'), child: const Icon(Icons.shopping_cart_outlined));
              },
            ),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartCheckoutScreen())),
          ),
        ],
      ),
      body: FutureBuilder<List<FoodItem>>(
        future: api.listFood(seller.sellerId),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No menu items yet.'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final f = items[i];
              final inCart = app.cart[f.id]?.quantity ?? 0;
              return ListTile(
                title: Text(f.name),
                subtitle: Text('\$${f.price.toStringAsFixed(2)}'),
                trailing: f.available
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(onPressed: () => app.removeFromCart(f.id), icon: const Icon(Icons.remove)),
                          Text('$inCart'),
                          IconButton(onPressed: () => app.addToCart(f), icon: const Icon(Icons.add)),
                        ],
                      )
                    : const Text('Sold out'),
              );
            },
          );
        },
      ),
    );
  }
}
