import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'home_shell.dart';
import 'university_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();
  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPass = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _tabs.dispose();
    _loginEmail.dispose();
    _loginPass.dispose();
    _regName.dispose();
    _regEmail.dispose();
    _regPass.dispose();
    super.dispose();
  }

  Future<void> _login(AppState app) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await app.login(_loginEmail.text.trim(), _loginPass.text);
      if (!mounted) return;
      if (!app.hasUniversity) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const UniversityScreen()));
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _register(AppState app) async {
    final uni = app.university;
    if (uni == null || uni.isEmpty) {
      setState(() => _error = 'Select your university first');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await app.register(
        name: _regName.text.trim(),
        email: _regEmail.text.trim(),
        password: _regPass.text,
        uni: uni,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Food'),
        leading: IconButton(
          icon: const Icon(Icons.school_outlined),
          tooltip: 'Change campus',
          onPressed: () async {
            await context.read<AppState>().clearUniversity();
          },
        ),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Sign in'), Tab(text: 'Register')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextField(
                controller: _loginEmail,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _loginPass,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                autofillHints: const [AutofillHints.password],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : () => _login(app),
                child: _busy ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Continue'),
              ),
            ],
          ),
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('University: ${app.university ?? "not set — go back and pick campus"}'),
              const SizedBox(height: 12),
              TextField(controller: _regName, decoration: const InputDecoration(labelText: 'Full name')),
              const SizedBox(height: 12),
              TextField(
                controller: _regEmail,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(controller: _regPass, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : () => _register(app),
                child: const Text('Create account'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
