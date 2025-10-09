// lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'change_password_page.dart';
import 'about_page.dart';
import 'google_auth_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color tealStart = Color(0xFF06B6A4);
    const Color tealEnd = Color(0xFF0EA5E9);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Configuración"),
        backgroundColor: tealStart,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [tealStart, tealEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.teal),
                  title: const Text('Perfil'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // ✅ CORREGIDO: Ocultar cambio de contraseña para usuarios Google
              FutureBuilder<bool>(
                future: GoogleAuthService.isGoogleUser(),
                builder: (context, snapshot) {
                  final isGoogleUser = snapshot.data ?? false;

                  if (!isGoogleUser) {
                    return Column(
                      children: [
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.lock, color: Colors.teal),
                            title: const Text('Cambiar contraseña'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  } else {
                    return const SizedBox(); // Oculta para Google
                  }
                },
              ),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.info, color: Colors.teal),
                  title: const Text('Acerca de'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutPage()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}