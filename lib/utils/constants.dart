// lib/utils/constants.dart
// ============================================================
// CONSTANTES CENTRALIZADAS — Nova App Móvil
// ============================================================
// Única fuente de verdad para:
//   • URL del backend
//   • Endpoints de la API
//   • Keys de SharedPreferences
//   • Configuración de la app
// ============================================================

class AppConstants {
  AppConstants._(); // No instanciable

  // ─── Backend ────────────────────────────────────────────
  // ⚠️ Cambiar esta IP cuando se mueva el servidor
  static const String backendUrl = 'http://192.168.2.179:3000';

  // ─── Endpoints AUTH ─────────────────────────────────────
  static const String loginEndpoint       = '/login';
  static const String registerEndpoint    = '/users/register';
  static const String googleAuthEndpoint  = '/users/google-auth';

  // ─── Endpoints PLACES ───────────────────────────────────
  static const String placesEndpoint      = '/places';
  static const String placesByTypeEndpoint = '/places/type'; // + /{type}
  static const String placeByIdEndpoint   = '/places';       // + /{id}

  // ─── Endpoints SCAN ─────────────────────────────────────
  static const String scanEndpoint      = '/scans';
  static const String myHistoryEndpoint = '/scans/my-history';
  static const String qrValidateEndpoint = '/qr/validate';

  // ─── Endpoints USER ─────────────────────────────────────
  static const String userProfileEndpoint  = '/users/me/profile';
  static const String userPasswordEndpoint = '/users/me/password';
  static const String myRewardsEndpoint    = '/rewards/my-rewards';

  // ─── Endpoints HEALTH ───────────────────────────────────
  static const String healthEndpoint = '/health';

  // ─── SharedPreferences Keys ─────────────────────────────
  static const String keyToken       = 'auth_token';
  static const String keyUserId      = 'userId';
  static const String keyUser        = 'user';
  static const String keyUsername     = 'username';
  static const String keyEmail       = 'email';
  static const String keyFirstName   = 'first_name';
  static const String keyAuthProvider = 'auth_provider';
  static const String keySavedEmail  = 'savedEmail';
  static const String keyRememberMe  = 'rememberMe';

  // ─── Roles ──────────────────────────────────────────────
  static const String roleAdmin     = 'admin_general';
  static const String roleSecretary = 'user_general';
  static const String roleOwner     = 'user_place';

  // ─── Timeouts ───────────────────────────────────────────
  static const Duration timeoutShort  = Duration(seconds: 5);
  static const Duration timeoutNormal = Duration(seconds: 10);
  static const Duration timeoutLong   = Duration(seconds: 15);

  // ─── Helpers ────────────────────────────────────────────
  static String buildUrl(String endpoint) => '$backendUrl$endpoint';
}