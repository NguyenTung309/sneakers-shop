import 'package:flutter/material.dart';

import '../../../services/api_service.dart';
import '../../auth/login_screen.dart';
import '../../navigator.dart';

class BodyProfile extends StatefulWidget {
  const BodyProfile({super.key});

  @override
  State<BodyProfile> createState() => _BodyProfileState();
}

class _BodyProfileState extends State<BodyProfile> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String _fullName = '';
  String _email = '';
  String _role = 'Guest';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final loggedIn = await ApiService.isLoggedIn();
    final fullName = await ApiService.getFullName();
    final email = await ApiService.getEmail();
    final role = await ApiService.getRole();

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoggedIn = loggedIn;
      _fullName = (fullName == null || fullName.isEmpty) ? 'Guest User' : fullName;
      _email = email ?? '';
      _role = role ?? 'Guest';
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    await ApiService.removeToken();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigator()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        child: Text(
                          _fullName.isNotEmpty ? _fullName.substring(0, 1).toUpperCase() : 'G',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _fullName,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(_email.isEmpty ? 'Not logged in' : _email),
                            const SizedBox(height: 4),
                            Chip(label: Text(_role)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_isLoggedIn) ...[
                    const ListTile(
                      leading: Icon(Icons.shopping_bag_outlined),
                      title: Text('Use the Cart tab to review selected products'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.receipt_long_outlined),
                      title: Text('Use the Orders tab to filter and reorder previous purchases'),
                    ),
                    if (_role == 'Admin')
                      const ListTile(
                        leading: Icon(Icons.admin_panel_settings_outlined),
                        title: Text('Admin tools are available in the Admin tab'),
                      ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                    ),
                  ] else ...[
                    const Text(
                      'Browse products freely and login only when you want to add to cart, buy now, checkout or view your order history.',
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ).then((_) => _loadProfile());
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Login / Register'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
