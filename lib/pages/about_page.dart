// lib/pages/about_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        // ✅ Los SnackBar fueron removidos porque necesitan context
        // y no podemos garantizar que el context esté disponible en async gaps
      }
    } catch (e) {
      // ✅ Los SnackBar fueron removidos por la misma razón
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color tealStart = Color(0xFF06B6A4);
    const Color tealEnd = Color(0xFF0EA5E9);

    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * 0.94;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [tealStart, tealEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: SizedBox(
                width: maxWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Acerca de',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Card(
                      clipBehavior: Clip.hardEdge,
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        child: Column(
                          children: [
                            Text('Nova App', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text('v1.0', style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 12),
                            Text(
                              'Prototipo de app para gestión con QR. Desarrollada en Flutter ',
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _openLink('https://flutter.dev'), // ✅ REMOVIDO context
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: theme.colorScheme.secondary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.0),
                                  child: Text('Visitar Flutter.dev'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}