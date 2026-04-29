// lib/pages/dashboard_page.dart
// FIX FINAL: StatsDashboardPage sin parámetros (arquitectura nueva)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../services/admin_service.dart';
import 'stats_dashboard_page.dart';
import 'places/list_tab.dart';
import 'admins/list_tab.dart';
import 'users_page.dart';
import 'rewards_page.dart';
import 'reports_page.dart';
import 'profile/profile_page.dart';
import 'profile/change_password_dialog.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const _teal = Color(0xFF06B6A4);

  int _selectedIndex = 0;
  String _userName = '';
  String _userEmail = '';
  String _userRole = '';
  int? _userId;
  bool _loaded = false;
  String _currentPlaceFilter = 'all';
  bool _sidebarExpanded = false;

  @override
  void initState() {
    super.initState();
    _init();
    _loadSidebarState();
  }

  Future<void> _loadSidebarState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _sidebarExpanded = prefs.getBool('sidebarExpanded') ?? false);
    }
  }

  Future<void> _toggleSidebar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _sidebarExpanded = !_sidebarExpanded);
    await prefs.setBool('sidebarExpanded', _sidebarExpanded);
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();

    final role = prefs.getString(AppConstants.keyUserRole) ?? '';
    final name = prefs.getString(AppConstants.keyUserName) ?? 'Usuario';
    final email = prefs.getString(AppConstants.keyUserEmail) ?? '';
    final placeId = prefs.getInt('placeId');
    final userId = prefs.getInt(AppConstants.keyUserId);

    if (role == AppConstants.roleUserPlace) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/owner-dashboard',
              (_) => false,
          arguments: {
            'placeId': placeId,
            'userName': name,
            'userEmail': email,
          },
        );
      }
      return;
    }

    if (role != AppConstants.roleAdminGeneral &&
        role != AppConstants.roleUserGeneral) {
      await AdminService.logout();
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (_) => false);
      }
      return;
    }

    setState(() {
      _userName = name;
      _userEmail = email;
      _userRole = role;
      _userId = userId;
      _loaded = true;
    });
  }

  bool get _canEdit => _userRole == AppConstants.roleAdminGeneral;
  bool get _canViewInfo => _userRole == AppConstants.roleAdminGeneral;
  bool get _showAdmins => _userRole == AppConstants.roleAdminGeneral;

  int get _placesIndex => 1;
  int get _rewardsIndex => _showAdmins ? 4 : 2;
  int get _reportsIndex => _showAdmins ? 5 : 3;

  void _navigateTo(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() => _selectedIndex = index);
    }
  }

  void _navigateToPlaces(String filter) {
    setState(() {
      _currentPlaceFilter = filter;
      _selectedIndex = _placesIndex;
    });
  }

  // ✅ CORREGIDO AQUÍ
  List<Widget> get _pages => [
    const StatsDashboardPage(),
    PlacesListTab(
      canEdit: _canEdit,
      canViewInfo: _canViewInfo,
      initialFilter: _currentPlaceFilter,
      key: ValueKey(_currentPlaceFilter),
    ),
    if (_showAdmins) AdminsListTab(canEdit: _canEdit),
    if (_showAdmins) const UsersPage(),
    const RewardsPage(),
    const ReportsPage(),
  ];

  List<_NavItem> get _navItems => [
    _NavItem(icon: Icons.home_rounded, label: 'Inicio'),
    _NavItem(icon: Icons.place_rounded, label: 'Lugares'),
    if (_showAdmins)
      _NavItem(icon: Icons.admin_panel_settings, label: 'Administradores'),
    if (_showAdmins)
      _NavItem(icon: Icons.people_rounded, label: 'Turistas'),
    _NavItem(icon: Icons.card_giftcard_rounded, label: 'Recompensas'),
    _NavItem(icon: Icons.analytics_rounded, label: 'Reportes'),
  ];

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _teal,
        title: Row(
          children: [
            IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _sidebarExpanded ? Icons.menu_open : Icons.menu,
                  key: ValueKey(_sidebarExpanded),
                  color: Colors.white,
                ),
              ),
              onPressed: _toggleSidebar,
            ),
            const SizedBox(width: 4),
            const Icon(Icons.qr_code_scanner, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              'Nova App Dashboard',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [_userMenu(), const SizedBox(width: 16)],
      ),
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: _sidebarExpanded ? 200 : 64,
            child: _buildNavigationRail(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildNavigationRail() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (_, i) {
                final item = _navItems[i];
                final selected = _selectedIndex == i;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIndex = i;
                      if (i == _placesIndex) _currentPlaceFilter = 'all';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    color: selected ? _teal.withOpacity(0.12) : null,
                    child: Row(
                      children: [
                        Icon(item.icon,
                            color: selected ? _teal : Colors.grey),
                        if (_sidebarExpanded)
                          const SizedBox(width: 10),
                        if (_sidebarExpanded) Text(item.label),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _userMenu() {
    return PopupMenuButton<String>(
      onSelected: (v) {
        if (v == 'logout') _confirmLogout();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'logout', child: Text('Cerrar sesión')),
      ],
      child: const Icon(Icons.account_circle, color: Colors.white),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres salir?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await AdminService.logout();
              if (mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (_) => false);
              }
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}