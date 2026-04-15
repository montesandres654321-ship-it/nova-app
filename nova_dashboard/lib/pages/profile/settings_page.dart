// lib/pages/profile/settings_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifications = true;
  bool _emailNotifications = true;
  bool _autoRefresh = true;
  String _language = 'es';
  String _dateFormat = 'dd/MM/yyyy';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifications = prefs.getBool('notifications') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _autoRefresh = prefs.getBool('auto_refresh') ?? true;
      _language = prefs.getString('language') ?? 'es';
      _dateFormat = prefs.getString('date_format') ?? 'dd/MM/yyyy';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('Notificaciones'),
          _buildSwitchTile(
            'Notificaciones push',
            'Recibir notificaciones en tiempo real',
            _notifications,
                (v) {
              setState(() => _notifications = v);
              _saveSetting('notifications', v);
            },
          ),
          _buildSwitchTile(
            'Notificaciones por email',
            'Recibir resúmenes por correo',
            _emailNotifications,
                (v) {
              setState(() => _emailNotifications = v);
              _saveSetting('email_notifications', v);
            },
          ),
          const Divider(height: 32),
          _buildSection('Interfaz'),
          _buildSwitchTile(
            'Auto-actualizar',
            'Actualizar datos automáticamente',
            _autoRefresh,
                (v) {
              setState(() => _autoRefresh = v);
              _saveSetting('auto_refresh', v);
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Idioma'),
            subtitle: Text(_language == 'es' ? 'Español' : 'English'),
            trailing: DropdownButton<String>(
              value: _language,
              underline: Container(),
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
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Formato de fecha'),
            subtitle: Text(_dateFormat),
            trailing: DropdownButton<String>(
              value: _dateFormat,
              underline: Container(),
              items: const [
                DropdownMenuItem(value: 'dd/MM/yyyy', child: Text('DD/MM/AAAA')),
                DropdownMenuItem(value: 'MM/dd/yyyy', child: Text('MM/DD/AAAA')),
                DropdownMenuItem(value: 'yyyy-MM-dd', child: Text('AAAA-MM-DD')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _dateFormat = v);
                  _saveSetting('date_format', v);
                }
              },
            ),
          ),
          const Divider(height: 32),
          _buildSection('Avanzado'),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Limpiar caché', style: TextStyle(color: Colors.red)),
            onTap: _clearCache,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.teal,
    );
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar caché'),
        content: const Text('¿Estás seguro? Esto eliminará todos los datos temporales.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Aquí limpiarías el caché real
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caché limpiado'), backgroundColor: Colors.green),
      );
    }
  }
}