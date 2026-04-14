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
  String? _preset;

  static const _presets = [
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
    final u = (_preset ?? _custom.text.trim());
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
          ..._presets.map(
            (p) => RadioListTile<String>(
              value: p,
              groupValue: _preset,
              title: Text(p),
              onChanged: (v) => setState(() {
                _preset = v;
                _custom.clear();
              }),
            ),
          ),
          const Divider(),
          TextField(
            controller: _custom,
            decoration: const InputDecoration(
              labelText: 'Or type your school name',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() => _preset = null),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _continue, child: const Text('Continue')),
        ],
      ),
    );
  }
}
