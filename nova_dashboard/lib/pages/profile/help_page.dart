// lib/pages/profile/help_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayuda y Soporte'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('Preguntas Frecuentes'),
          _buildFaqItem(
            '¿Cómo crear un nuevo lugar?',
            'Ve a la sección "Lugares", haz clic en el botón "Nuevo Lugar" y completa el formulario con la información requerida.',
            Icons.help_outline,
          ),
          _buildFaqItem(
            '¿Cómo asignar un propietario a un lugar?',
            'Al crear o editar un lugar, selecciona un propietario del menú desplegable. Solo aparecen propietarios sin lugar asignado.',
            Icons.person_add,
          ),
          _buildFaqItem(
            '¿Cómo generar el código QR?',
            'El código QR se genera automáticamente al crear un lugar. Puedes verlo y descargarlo desde la lista de lugares.',
            Icons.qr_code,
          ),
          _buildFaqItem(
            '¿Cómo ver las estadísticas?',
            'En la pestaña "Inicio" encontrarás un dashboard completo con gráficas y estadísticas de todos los lugares y recompensas.',
            Icons.analytics,
          ),
          const Divider(height: 32),
          _buildSection('Contacto'),
          ListTile(
            leading: const Icon(Icons.email, color: Colors.teal),
            title: const Text('Correo de soporte'),
            subtitle: const Text('soporte@novaapp.com'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _launchEmail('soporte@novaapp.com'),
          ),
          ListTile(
            leading: const Icon(Icons.phone, color: Colors.teal),
            title: const Text('Teléfono'),
            subtitle: const Text('+57 300 123 4567'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _launchPhone('+573001234567'),
          ),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.teal),
            title: const Text('Sitio web'),
            subtitle: const Text('www.novaapp.com'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _launchUrl('https://www.novaapp.com'),
          ),
          const Divider(height: 32),
          _buildSection('Recursos'),
          ListTile(
            leading: const Icon(Icons.video_library, color: Colors.teal),
            title: const Text('Tutoriales en video'),
            subtitle: const Text('Aprende con videos paso a paso'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showInfo(context, 'Próximamente disponible'),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book, color: Colors.teal),
            title: const Text('Manual de usuario'),
            subtitle: const Text('Guía completa del sistema'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showInfo(context, 'Próximamente disponible'),
          ),
          const Divider(height: 32),
          _buildSection('Acerca de'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.qr_code_scanner, size: 64, color: Colors.teal),
                const SizedBox(height: 16),
                const Text(
                  'Nova App Dashboard',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Versión 1.0.0',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Text(
                  '© 2024 Nova App. Todos los derechos reservados.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
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

  Widget _buildFaqItem(String question, String answer, IconData icon) {
    return ExpansionTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(question),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            answer,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}