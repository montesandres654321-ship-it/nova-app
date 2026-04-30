// lib/pages/profile/settings_page.dart
// ============================================================
// REDESIGN: SaaS settings panel · categorías · items premium
// Lógica sin cambios
// ============================================================
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Design tokens ─────────────────────────────────────────────
const _kPrimary   = Color(0xFF06B6A4);
const _kBgPage    = Color(0xFFF1F5F9);
const _kTextHead  = Color(0xFF0F172A);
const _kTextMuted = Color(0xFF64748B);
const _kTextSub   = Color(0xFF94A3B8);
const _kBorder    = Color(0xFFE2E8F0);
const _kBlue      = Color(0xFF3B82F6);
const _kAmber     = Color(0xFFF59E0B);
const _kRed       = Color(0xFFEF4444);

// ─────────────────────────────────────────────────────────────
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  // ── State — SIN CAMBIOS ───────────────────────────────
  bool   _notifications      = true;
  bool   _emailNotifications = true;
  bool   _autoRefresh        = true;
  String _language           = 'es';
  String _dateFormat         = 'dd/MM/yyyy';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // ── LÓGICA — SIN CAMBIOS ─────────────────────────────
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifications      = prefs.getBool('notifications')       ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _autoRefresh        = prefs.getBool('auto_refresh')        ?? true;
      _language           = prefs.getString('language')          ?? 'es';
      _dateFormat         = prefs.getString('date_format')       ?? 'dd/MM/yyyy';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool)   { await prefs.setBool(key, value); }
    else if (value is String) { await prefs.setString(key, value); }
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: _kRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.cleaning_services_rounded,
                  color: _kRed, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('¿Limpiar caché?',
                style: TextStyle(fontSize: 17,
                    fontWeight: FontWeight.w800, color: _kTextHead)),
            const SizedBox(height: 8),
            const Text('Se eliminarán todos los datos temporales.',
                style: TextStyle(fontSize: 13, color: _kTextMuted),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kTextMuted,
                  side: const BorderSide(color: _kBorder),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Cancelar',
                    style: TextStyle(fontSize: 13)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRed,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Limpiar',
                    style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600)),
              )),
            ]),
          ]),
        ),
      ),
    );

    if (confirm == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Caché limpiado'),
          backgroundColor: Colors.green));
    }
  }

  // ─────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kTextHead,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Configuración',
            style: TextStyle(fontSize: 16,
                fontWeight: FontWeight.w600, color: _kTextHead)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: _kBorder),
        ),
      ),
      body: LayoutBuilder(builder: (_, constraints) {
        final isWide = constraints.maxWidth > 700;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 28.0 : 16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── Notificaciones ─────────────────
                  _SettingsCard(title: 'Notificaciones', children: [
                    _toggleRow(
                      icon: Icons.notifications_outlined,
                      iconColor: _kPrimary,
                      title: 'Notificaciones push',
                      subtitle: 'Alertas en tiempo real',
                      value: _notifications,
                      onChanged: (v) {
                        setState(() => _notifications = v);
                        _saveSetting('notifications', v);
                      },
                    ),
                    _itemDivider(),
                    _toggleRow(
                      icon: Icons.mail_outline_rounded,
                      iconColor: _kBlue,
                      title: 'Notificaciones por email',
                      subtitle: 'Resúmenes por correo',
                      value: _emailNotifications,
                      onChanged: (v) {
                        setState(() => _emailNotifications = v);
                        _saveSetting('email_notifications', v);
                      },
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // ── Preferencias ───────────────────
                  _SettingsCard(title: 'Preferencias', children: [
                    _toggleRow(
                      icon: Icons.sync_rounded,
                      iconColor: _kAmber,
                      title: 'Auto-actualizar',
                      subtitle: 'Recargar datos automáticamente',
                      value: _autoRefresh,
                      onChanged: (v) {
                        setState(() => _autoRefresh = v);
                        _saveSetting('auto_refresh', v);
                      },
                    ),
                    _itemDivider(),
                    _dropdownRow(
                      icon: Icons.language_rounded,
                      iconColor: _kBlue,
                      title: 'Idioma',
                      subtitle: 'Idioma de la interfaz',
                      trailing: _styledDropdown<String>(
                        value: _language,
                        items: const [
                          DropdownMenuItem(value: 'es', child: Text('Español')),
                          DropdownMenuItem(value: 'en', child: Text('English')),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _language = v);
                            _saveSetting('language', v);
                          }
                        },
                      ),
                    ),
                    _itemDivider(),
                    _dropdownRow(
                      icon: Icons.calendar_today_rounded,
                      iconColor: _kPrimary,
                      title: 'Formato de fecha',
                      subtitle: 'Cómo se muestran las fechas',
                      trailing: _styledDropdown<String>(
                        value: _dateFormat,
                        items: const [
                          DropdownMenuItem(
                              value: 'dd/MM/yyyy',
                              child: Text('DD/MM/AAAA')),
                          DropdownMenuItem(
                              value: 'MM/dd/yyyy',
                              child: Text('MM/DD/AAAA')),
                          DropdownMenuItem(
                              value: 'yyyy-MM-dd',
                              child: Text('AAAA-MM-DD')),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _dateFormat = v);
                            _saveSetting('date_format', v);
                          }
                        },
                      ),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // ── Sistema ────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFFEE2E2)),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8, offset: const Offset(0, 2),
                      )],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                          child: Row(children: [
                            Container(
                              width: 6, height: 6,
                              decoration: const BoxDecoration(
                                  color: _kRed, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            const Text('Sistema',
                                style: TextStyle(fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _kRed)),
                          ]),
                        ),
                        const Divider(height: 20, thickness: 0.5,
                            color: Color(0xFFFEE2E2)),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                          child: _dangerRow(
                            icon: Icons.cleaning_services_rounded,
                            title: 'Limpiar caché',
                            subtitle:
                                'Eliminar datos temporales del sistema',
                            onTap: _clearCache,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────
  // ROW WIDGETS
  // ─────────────────────────────────────────────────────
  Widget _toggleRow({
    required IconData         icon,
    required Color            iconColor,
    required String           title,
    required String           subtitle,
    required bool             value,
    required ValueChanged<bool> onChanged,
  }) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        _iconBox(icon, iconColor),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w600, color: _kTextHead)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(fontSize: 11, color: _kTextSub)),
          ],
        )),
        Transform.scale(
          scale: 0.85,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _kPrimary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ]),
    );

  Widget _dropdownRow({
    required IconData icon,
    required Color    iconColor,
    required String   title,
    required String   subtitle,
    required Widget   trailing,
  }) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        _iconBox(icon, iconColor),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w600, color: _kTextHead)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(fontSize: 11, color: _kTextSub)),
          ],
        )),
        trailing,
      ]),
    );

  Widget _dangerRow({
    required IconData     icon,
    required String       title,
    required String       subtitle,
    required VoidCallback onTap,
  }) =>
    InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _kRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: _kRed),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w600, color: _kRed)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: _kTextSub)),
            ],
          )),
          Icon(Icons.arrow_forward_ios_rounded, size: 13,
              color: _kRed.withOpacity(0.4)),
        ]),
      ),
    );

  Widget _iconBox(IconData icon, Color color) => Container(
    width: 40, height: 40,
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, size: 18, color: color),
  );

  Widget _styledDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _kBgPage,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _kBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.expand_more_rounded,
              size: 15, color: _kTextMuted),
          style: const TextStyle(fontSize: 12, color: _kTextHead),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );

  Widget _itemDivider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 2),
    child: Divider(height: 1, thickness: 0.5, color: _kBorder),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS CARD (sección con título + lista de items)
// ─────────────────────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final String       title;
  final List<Widget> children;
  const _SettingsCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _kBorder),
      boxShadow: [BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 8, offset: const Offset(0, 2),
      )],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
        child: Text(title,
            style: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w700, color: _kTextHead)),
      ),
      const Divider(height: 20, thickness: 0.5, color: _kBorder),
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        child: Column(children: children),
      ),
    ]),
  );
}
