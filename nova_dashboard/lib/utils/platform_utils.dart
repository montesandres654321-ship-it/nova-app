// lib/utils/platform_utils.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show AnchorElement, Blob, Url;

class PlatformUtils {
  static bool get isWeb => kIsWeb;

  static bool get isMobile => !kIsWeb && (
      defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android
  );

  static bool get isDesktop => !kIsWeb && (
      defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux
  );

  static String get platformName {
    if (isWeb) return 'Web';
    if (isMobile) return 'Mobile';
    if (isDesktop) return 'Desktop';
    return 'Unknown';
  }

  // Métodos útiles adicionales
  static bool get isAndroid => !isWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get isIOS => !isWeb && defaultTargetPlatform == TargetPlatform.iOS;
  static bool get isWindows => !isWeb && defaultTargetPlatform == TargetPlatform.windows;
  static bool get isMacOS => !isWeb && defaultTargetPlatform == TargetPlatform.macOS;
  static bool get isLinux => !isWeb && defaultTargetPlatform == TargetPlatform.linux;

  /// Descarga un archivo según la plataforma (Web o Móvil)
  static Future<void> downloadFile({
    required Uint8List bytes,
    required String fileName,
    String mimeType = 'application/octet-stream',
  }) async {
    if (isWeb) {
      // WEB: Usar HTML download
      _downloadFileWeb(bytes, fileName, mimeType);
    } else {
      // MÓVIL/DESKTOP: Por implementar
      // En producción necesitarías:
      // import 'package:path_provider/path_provider.dart';
      // import 'dart:io';
      throw UnimplementedError(
        'Descarga en móvil/desktop no implementada aún. '
            'Implementar con path_provider y permission_handler',
      );
    }
  }

  /// Descarga de archivo para WEB
  static void _downloadFileWeb(
      Uint8List bytes,
      String fileName,
      String mimeType,
      ) {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}