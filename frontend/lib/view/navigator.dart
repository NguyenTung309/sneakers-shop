import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'admin_dashboard_screen.dart';
import 'bag/bag_screen.dart';
import 'home/home_screen.dart';
import 'order_history_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _role;

  @override
  void initState() {
    super.initState();
    _reloadSession();
  }

  Future<void> _reloadSession() async {
    final role = await ApiService.getRole();
    if (!mounted) return;
    setState(() {
      _role = role;
      _isLoading = false;
    });
  }

  List<_NavItem> get _items {
    final common = <_NavItem>[
      // FIX: dùng HomeScreen (UI đẹp hơn) thay vì ProductListScreen
      const _NavItem(
        label: 'Discover',
        icon: Icons.explore_outlined,
        selectedIcon: Icons.explore,
        screen: HomeScreen(),
      ),
      const _NavItem(
        label: 'Cart',
        icon: Icons.shopping_bag_outlined,
        selectedIcon: Icons.shopping_bag,
        screen: MyBagScreen(),
      ),
      const _NavItem(
        label: 'Orders',
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
        screen: OrderHistoryScreen(),
      ),
    ];

    if (_role == 'Admin') {
      return [
        ...common,
        const _NavItem(
          label: 'Admin',
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings,
          screen: AdminDashboardScreen(),
        ),
      ];
    }

    return [
      ...common,
      const _NavItem(
        label: 'Profile',
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        screen: Profile(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final items = _items;
    if (_selectedIndex >= items.length) _selectedIndex = 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 960;
        final body = IndexedStack(
          index: _selectedIndex,
          children: items.map((item) => item.screen).toList(),
        );

        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _selectedIndex = index),
                  labelType: NavigationRailLabelType.all,
                  destinations: items
                      .map((item) => NavigationRailDestination(
                            icon: Icon(item.icon),
                            selectedIcon: Icon(item.selectedIcon),
                            label: Text(item.label),
                          ))
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
          );
        }

        return Scaffold(
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            destinations: items
                .map((item) => NavigationDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: item.label,
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
}