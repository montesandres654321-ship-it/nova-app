// lib/pages/dashboard_page.dart
// ============================================================
// FIX: pasa callbacks a StatsDashboardPage para que las cards
//      redirijan correctamente
// FIX: menú usuario completo con perfil, contraseña, cerrar sesión
// FIX: nombre y rol del usuario en AppBar
// ============================================================

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
    final prefs = await SharedPreferences.getInstance();
    final role    = prefs.getString(AppConstants.keyUserRole) ?? '';
    final name    = prefs.getString(AppConstants.keyUserName) ?? 'Usuario';
    final email   = prefs.getString(AppConstants.keyUserEmail) ?? '';
    final placeId = prefs.getInt('placeId');
    final userId  = prefs.getInt(AppConstants.keyUserId);

    if (role == AppConstants.roleUserPlace) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/owner-dashboard', (_) => false,
            arguments: {'placeId': placeId, 'userName': name, 'userEmail': email});
      }
      return;
    }

    if (role != AppConstants.roleAdminGeneral && role != AppConstants.roleUserGeneral) {
      await AdminService.logout();
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      return;
    }

    setState(() { _userName = name; _userEmail = email; _userRole = role; _userId = userId; _loaded = true; });
  }

  bool get _canEdit => _userRole == AppConstants.roleAdminGeneral;
  bool get _canViewInfo => _userRole == AppConstants.roleAdminGeneral || _userRole == AppConstants.roleUserGeneral;
  bool get _showAdmins => _userRole == AppConstants.roleAdminGeneral;

  int get _placesIndex => 1;
  int get _adminsIndex => _showAdmins ? 2 : -1;
  int get _usersIndex => _showAdmins ? 3 : 2;
  int get _rewardsIndex => _showAdmins ? 4 : 3;
  int get _reportsIndex => _showAdmins ? 5 : 4;

  void _navigateTo(int index) {
    if (index >= 0 && index < _pages.length) setState(() => _selectedIndex = index);
  }

  void _navigateToPlaces(String filter) {
    setState(() { _currentPlaceFilter = filter; _selectedIndex = _placesIndex; });
  }

  List<Widget> get _pages => [
    // FIX: pasar callbacks para que las cards y botones redirijan
    StatsDashboardPage(
      onNavigate: _navigateTo,
      onNavigateToPlaces: _navigateToPlaces,
      placesIndex: _placesIndex,
      rewardsIndex: _rewardsIndex,
      reportsIndex: _reportsIndex,
    ),
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
          ),
          const SizedBox(width: 4),
          const Icon(Icons.qr_code_scanner, color: Colors.white),
          const SizedBox(width: 8),
          const Text('Nova App Dashboard', style: TextStyle(color: Colors.white)),
        ]),
        actions: [
          // FIX: menú usuario completo con nombre, rol, perfil, contraseña, cerrar sesión
          _buildUserMenu(),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(children: [
        AnimatedContainer(duration: const Duration(milliseconds: 250),
            width: _sidebarExpanded ? 200 : 64, child: _buildNavigationRail()),
        const VerticalDivider(width: 1),
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
          final item = _navItems[i];
          final selected = _selectedIndex == i;
          return InkWell(
            onTap: () { setState(() { _selectedIndex = i; if (i == _placesIndex) _currentPlaceFilter = 'all'; }); },
            child: Container(
              padding: const EdgeInsets.all(10),
              color: selected ? _teal.withOpacity(0.12) : null,
              child: Row(children: [
                Icon(item.icon, color: selected ? _teal : Colors.grey),
                if (_sidebarExpanded) ...[
                  const SizedBox(width: 10),
                  Expanded(child: Text(item.label,
                      style: TextStyle(color: selected ? _teal : Colors.grey[700],
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal, fontSize: 13),
                      overflow: TextOverflow.ellipsis)),
                ],
              ]),
            ),
          );
        },
      )),
    ]));
  }

  // FIX: menú completo con nombre, email, rol, perfil, contraseña, cerrar sesión
  Widget _buildUserMenu() {
    final roleLabel = AppConstants.getRoleLabel(_userRole);
    final roleEmoji = AppConstants.getRoleEmoji(_userRole);

    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(radius: 16, backgroundColor: Colors.white,
              child: Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                  style: const TextStyle(color: _teal, fontWeight: FontWeight.bold, fontSize: 14))),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(_userName.split(' ').first, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            Text('$roleEmoji $roleLabel', style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ]),
          const Icon(Icons.arrow_drop_down, color: Colors.white),
        ]),
      ),
      itemBuilder: (_) => [
        // Header del menú
        PopupMenuItem(enabled: false, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(_userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(_userEmail, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text('$roleEmoji $roleLabel', style: const TextStyle(fontSize: 10, color: _teal))),
          const Divider(),
        ])),
        // Mi Perfil
        const PopupMenuItem(value: 'profile', child: ListTile(
            leading: Icon(Icons.person_rounded, color: _teal),
            title: Text('Mi Perfil'), contentPadding: EdgeInsets.zero, dense: true)),
        // Cambiar Contraseña
        const PopupMenuItem(value: 'password', child: ListTile(
            leading: Icon(Icons.lock_rounded, color: _teal),
            title: Text('Cambiar Contraseña'), contentPadding: EdgeInsets.zero, dense: true)),
        const PopupMenuDivider(),
        // Cerrar Sesión
        const PopupMenuItem(value: 'logout', child: ListTile(
            leading: Icon(Icons.logout_rounded, color: Colors.red),
            title: Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero, dense: true)),
      ],
      onSelected: (v) {
        switch (v) {
          case 'profile':
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfilePage()));
            break;
          case 'password':
            if (_userId != null) showDialog(context: context, builder: (_) => ChangePasswordDialog(userId: _userId!));
            break;
          case 'logout':
            _confirmLogout();
            break;
        }
      },
    );
  }

  void _confirmLogout() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Cerrar sesión'),
      content: const Text('¿Seguro que quieres salir?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () async { await AdminService.logout();
          if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false); },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          child: const Text('Salir'),
        ),
      ],
    ));
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}