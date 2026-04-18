// lib/pages/dashboard_page.dart
// FIX: Color exacto 0xFF06B6A4 en AppBar y sidebar (era Colors.teal genérico)
// Todo lo demás sin cambios funcionales

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../services/admin_service.dart';
import 'home/home_tab.dart';
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

  int    _selectedIndex     = 0;
  String _userName          = '';
  String _userEmail         = '';
  String _userRole          = '';
  int?   _userId;
  bool   _loaded            = false;
  String _currentPlaceFilter = 'all';
  bool   _sidebarExpanded   = false;

  @override
  void initState() { super.initState(); _init(); _loadSidebarState(); }

  Future<void> _loadSidebarState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _sidebarExpanded = prefs.getBool('sidebarExpanded') ?? false);
  }

  Future<void> _toggleSidebar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _sidebarExpanded = !_sidebarExpanded);
    await prefs.setBool('sidebarExpanded', _sidebarExpanded);
  }

  Future<void> _init() async {
    final prefs   = await SharedPreferences.getInstance();
    final role    = prefs.getString(AppConstants.keyUserRole)  ?? '';
    final name    = prefs.getString(AppConstants.keyUserName)  ?? 'Usuario';
    final email   = prefs.getString(AppConstants.keyUserEmail) ?? '';
    final placeId = prefs.getInt('placeId');
    final userId  = prefs.getInt(AppConstants.keyUserId);

    if (role == AppConstants.roleUserPlace) {
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil(
          '/owner-dashboard', (_) => false,
          arguments: {'placeId': placeId, 'userName': name, 'userEmail': email});
      return;
    }
    if (role != AppConstants.roleAdminGeneral && role != AppConstants.roleUserGeneral) {
      await AdminService.logout();
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      return;
    }
    setState(() { _userName = name; _userEmail = email; _userRole = role; _userId = userId; _loaded = true; });
  }

  bool get _canEdit     => _userRole == AppConstants.roleAdminGeneral;
  bool get _canViewInfo => _userRole == AppConstants.roleAdminGeneral;
  bool get _showAdmins  => _userRole == AppConstants.roleAdminGeneral;

  int get _placesIndex  => 1;
  int get _rewardsIndex => _showAdmins ? 4 : 2;
  int get _reportsIndex => _showAdmins ? 5 : 3;

  void _navigateTo(int index) { if (index >= 0 && index < _pages.length) setState(() => _selectedIndex = index); }
  void _navigateToPlaces(String filter) { setState(() { _currentPlaceFilter = filter; _selectedIndex = _placesIndex; }); }

  List<Widget> get _pages => [
    HomeTab(onNavigate: _navigateTo, onNavigateToPlaces: _navigateToPlaces,
        placesIndex: _placesIndex, rewardsIndex: _rewardsIndex, reportsIndex: _reportsIndex),
    PlacesListTab(canEdit: _canEdit, canViewInfo: _canViewInfo,
        initialFilter: _currentPlaceFilter, key: ValueKey(_currentPlaceFilter)),
    if (_showAdmins) AdminsListTab(canEdit: _canEdit),
    if (_showAdmins) const UsersPage(),
    const RewardsPage(),
    const ReportsPage(),
  ];

  List<_NavItem> get _navItems => [
    _NavItem(icon: Icons.home_rounded, label: 'Inicio'),
    _NavItem(icon: Icons.place_rounded, label: 'Lugares'),
    if (_showAdmins) _NavItem(icon: Icons.admin_panel_settings, label: 'Administradores'),
    if (_showAdmins) _NavItem(icon: Icons.people_rounded, label: 'Turistas'),
    _NavItem(icon: Icons.card_giftcard_rounded, label: 'Recompensas'),
    _NavItem(icon: Icons.analytics_rounded, label: 'Reportes'),
  ];

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _teal,
        title: Row(children: [
          IconButton(
              icon: AnimatedSwitcher(duration: const Duration(milliseconds: 200),
                  child: Icon(_sidebarExpanded ? Icons.menu_open : Icons.menu,
                      key: ValueKey(_sidebarExpanded), color: Colors.white)),
              onPressed: _toggleSidebar,
              tooltip: _sidebarExpanded ? 'Colapsar menú' : 'Expandir menú'),
          const SizedBox(width: 4),
          const Icon(Icons.qr_code_scanner, color: Colors.white),
          const SizedBox(width: 8),
          const Text('Nova App Dashboard', style: TextStyle(color: Colors.white)),
        ]),
        actions: [_userMenu(), const SizedBox(width: 16)],
      ),
      body: Row(children: [
        AnimatedContainer(duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut, width: _sidebarExpanded ? 200 : 64,
            child: _buildNavigationRail()),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(child: _pages[_selectedIndex]),
      ]),
    );
  }

  Widget _buildNavigationRail() {
    return Container(color: Colors.white, child: Column(children: [
      const SizedBox(height: 12),
      Expanded(child: ListView.builder(
          itemCount: _navItems.length,
          itemBuilder: (_, i) {
            final item = _navItems[i]; final sel = _selectedIndex == i;
            return Tooltip(message: _sidebarExpanded ? '' : item.label, preferBelow: false,
                child: InkWell(
                  onTap: () => setState(() { _selectedIndex = i; if (i == _placesIndex) _currentPlaceFilter = 'all'; }),
                  child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    padding: EdgeInsets.symmetric(horizontal: _sidebarExpanded ? 12 : 8, vertical: 10),
                    decoration: BoxDecoration(color: sel ? _teal.withOpacity(0.12) : null, borderRadius: BorderRadius.circular(10)),
                    child: Row(mainAxisAlignment: _sidebarExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                        children: [
                          Icon(item.icon, color: sel ? _teal : Colors.grey[600], size: 22),
                          if (_sidebarExpanded) ...[const SizedBox(width: 12),
                            Expanded(child: Text(item.label, style: TextStyle(
                                color: sel ? _teal : Colors.grey[800],
                                fontWeight: sel ? FontWeight.w600 : FontWeight.normal, fontSize: 13),
                                overflow: TextOverflow.ellipsis))],
                        ]),
                  ),
                ));
          })),
      if (_sidebarExpanded) ...[
        const Divider(height: 1),
        Padding(padding: const EdgeInsets.all(10), child: Row(children: [
          CircleAvatar(radius: 16, backgroundColor: _teal,
              child: Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(_userName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
            Text(AppConstants.getRoleLabel(_userRole), style: TextStyle(fontSize: 10, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
          ])),
        ])),
      ],
    ]));
  }

  Widget _userMenu() {
    return PopupMenuButton<String>(offset: const Offset(0, 50),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(radius: 18, backgroundColor: Colors.white,
            child: Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                style: const TextStyle(color: _teal, fontWeight: FontWeight.bold))),
        const SizedBox(width: 8),
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          Text('${AppConstants.getRoleEmoji(_userRole)} ${AppConstants.getRoleLabel(_userRole)}',
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
        const Icon(Icons.arrow_drop_down, color: Colors.white),
      ]),
      itemBuilder: (_) => [
        PopupMenuItem(enabled: false, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(_userEmail, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text('${AppConstants.getRoleEmoji(_userRole)} ${AppConstants.getRoleLabel(_userRole)}', style: const TextStyle(fontSize: 12)),
          const Divider(),
        ])),
        const PopupMenuItem(value: 'profile', child: ListTile(leading: Icon(Icons.person), title: Text('Mi Perfil'), contentPadding: EdgeInsets.zero, dense: true)),
        const PopupMenuItem(value: 'change_password', child: ListTile(leading: Icon(Icons.lock), title: Text('Cambiar Contraseña'), contentPadding: EdgeInsets.zero, dense: true)),
        const PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text('Cerrar Sesión', style: TextStyle(color: Colors.red)), contentPadding: EdgeInsets.zero, dense: true)),
      ],
      onSelected: (v) {
        switch (v) {
          case 'profile': Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfilePage())); break;
          case 'change_password':
            if (_userId != null) showDialog(context: context, builder: (_) => ChangePasswordDialog(userId: _userId!));
            else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo obtener el ID')));
            break;
          case 'logout': _confirmLogout(); break;
        }
      },
    );
  }

  void _confirmLogout() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'), content: const Text('¿Estás seguro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async { await AdminService.logout(); if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false); },
              child: const Text('Sí, cerrar sesión', style: TextStyle(color: Colors.white))),
        ]));
  }
}

class _NavItem {
  final IconData icon; final String label;
  const _NavItem({required this.icon, required this.label});
}