import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'auth_screen.dart';
import 'home_shell.dart';

class UniversityScreen extends StatefulWidget {
  const UniversityScreen({super.key});

  @override
  State<UniversityScreen> createState() => _UniversityScreenState();
}

class _UniversityScreenState extends State<UniversityScreen> {
  final _custom = TextEditingController();

  static const _presets = [
    'Demo Campus',
    'State University',
    'Tech Institute',
    'Liberal Arts College',
  ];

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final app = context.read<AppState>();
    final u = _custom.text.trim();
    if (u.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose or enter a university')));
      return;
    }
    await app.setUniversity(u);
    if (!mounted) return;
    if (app.isLoggedIn) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your campus')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Select university', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              final query = textEditingValue.text.trim().toLowerCase();
              if (query.isEmpty) {
                return _presets;
              }
              return _presets.where((u) => u.toLowerCase().contains(query));
            },
            onSelected: (String selection) {
              _custom.text = selection;
            },
            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
              if (_custom.text.isNotEmpty && textEditingController.text != _custom.text) {
                textEditingController.text = _custom.text;
              }
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: 'Search or type your university',
                  hintText: 'Start typing to filter suggestions',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => _custom.text = value,
                onSubmitted: (_) => onFieldSubmitted(),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              final items = options.toList(growable: false);
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 6,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240, minWidth: 280),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final option = items[index];
                        return ListTile(
                          dense: true,
                          title: Text(option),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _continue, child: const Text('Continue')),
        ],
      ),
    );
  }
}
