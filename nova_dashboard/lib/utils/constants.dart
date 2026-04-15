// lib/utils/constants.dart
// ============================================================
// CONSTANTES GLOBALES — Nova Dashboard
// ============================================================
// ⚠️  CAMBIO DE IP: solo modificar backendUrl aquí
// ============================================================

class AppConstants {

  // ──────────────────────────────────────────────────────────
  // BACKEND URL
  // ⚠️  Cambiar SOLO aquí cuando cambie la IP del servidor
  // ──────────────────────────────────────────────────────────
  static const String backendUrl = 'http://172.17.8.226:3000';

  // ──────────────────────────────────────────────────────────
  // SHARED PREFERENCES KEYS
  // Deben coincidir con lo que guarda admin_service.dart
  // ──────────────────────────────────────────────────────────
  static const String keyToken     = 'auth_token';   // ← token JWT
  static const String keyUserId    = 'user_id';
  static const String keyUserName  = 'user_name';
  static const String keyUserEmail = 'user_email';
  static const String keyUserRole  = 'user_role';

  // ──────────────────────────────────────────────────────────
  // ROLES
  // ⚠️  CRÍTICO: deben coincidir exactamente con el backend
  //    admin_general → CRUD completo
  //    user_general  → solo lectura (era 'usuario_general' — typo corregido)
  //    user_place    → solo su lugar (era 'usuario_place' — typo corregido)
  // ──────────────────────────────────────────────────────────
  static const String roleAdminGeneral = 'admin_general';
  static const String roleUserGeneral  = 'user_general';   // ← corregido (antes: 'usuario_general')
  static const String roleUserPlace    = 'user_place';     // ← corregido (antes: 'usuario_place')

  // ──────────────────────────────────────────────────────────
  // ENDPOINTS — ADMIN USUARIOS
  // ──────────────────────────────────────────────────────────
  static const String createUserEndpoint        = '/admin/users/create';
  static const String editUserEndpoint          = '/admin/users/:id';
  static const String toggleUserEndpoint        = '/admin/users/:id/toggle';
  static const String changePasswordEndpoint    = '/users/change-password';

  // ──────────────────────────────────────────────────────────
  // ENDPOINTS — LUGARES
  // ──────────────────────────────────────────────────────────
  static const String placesEndpoint            = '/places';
  static const String placesTypeEndpoint        = '/places/type';
  static const String uploadImageEndpoint       = '/admin/upload-image';
  static const String reassignOwnerEndpoint     = '/admin/places/:id/reassign-owner';

  // ──────────────────────────────────────────────────────────
  // ENDPOINTS — ANALYTICS ESCANEOS
  // ⚠️  Corregidos para coincidir con analytics.routes.js
  // ──────────────────────────────────────────────────────────
  static const String scansStatsEndpoint        = '/analytics/stats/general';
  static const String scansByDayEndpoint        = '/analytics/scans/by-day';       // query: ?days=30
  static const String topPlacesByScansEndpoint  = '/analytics/scans/top-places';   // query: ?limit=10
  static const String scansByTypeEndpoint       = '/analytics/scans/by-hour';

  // ──────────────────────────────────────────────────────────
  // ENDPOINTS — ANALYTICS RECOMPENSAS
  // ──────────────────────────────────────────────────────────
  static const String rewardsStatsEndpoint      = '/analytics/rewards/stats';
  static const String rewardsByDayEndpoint      = '/analytics/rewards/by-day';     // query: ?days=30
  static const String topPlacesByRewardsEndpoint = '/analytics/rewards/top-places'; // query: ?limit=10
  static const String rewardsByTypeEndpoint     = '/analytics/rewards/by-type';

  // ──────────────────────────────────────────────────────────
  // ENDPOINTS — ESTADÍSTICAS DASHBOARD
  // ──────────────────────────────────────────────────────────
  static const String dashboardStatsEndpoint    = '/stats/dashboard';
  static const String analyticsGeneralEndpoint  = '/analytics/stats/general';
  static const String analyticsUsersEndpoint    = '/analytics/users/stats';
  static const String analyticsPlacesEndpoint   = '/analytics/places/stats';

  // ──────────────────────────────────────────────────────────
  // ENDPOINTS — PROPIETARIOS
  // ──────────────────────────────────────────────────────────
  static const String ownersEndpoint            = '/api/admins/owners';
  static const String ownersWithoutPlaceEndpoint = '/analytics/admins/owners-without-place';
  static const String adminsWithDetailsEndpoint = '/analytics/admins/users-with-details';

  // ──────────────────────────────────────────────────────────
  // IMAGEN CONFIG
  // ──────────────────────────────────────────────────────────
  static const int maxImageSizeBytes            = 2 * 1024 * 1024; // 2MB
  static const List<String> validImageExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  // ──────────────────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────────────────

  /// Reemplazar parámetros en endpoints (mantener para compatibilidad)
  /// Ejemplo: replaceParams('/users/:id', {'id': '123'}) → '/users/123'
  static String replaceParams(String endpoint, Map<String, String> params) {
    String result = endpoint;
    params.forEach((key, value) {
      result = result.replaceAll(':$key', value);
    });
    return result;
  }

  /// Construir endpoint con query params
  /// Ejemplo: buildUrl('/analytics/scans/by-day', {'days': '30'})
  static String buildUrl(String endpoint, [Map<String, String>? queryParams]) {
    if (queryParams == null || queryParams.isEmpty) return '$backendUrl$endpoint';
    final query = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$backendUrl$endpoint?$query';
  }

  /// Validar extensión de imagen
  static bool isValidImageExtension(String extension) {
    return validImageExtensions.contains(extension.toLowerCase());
  }

  /// Obtener emoji por rol
  static String getRoleEmoji(String role) {
    switch (role) {
      case roleAdminGeneral: return '👑';
      case roleUserGeneral:  return '📋';
      case roleUserPlace:    return '🏪';
      default:               return '👤';
    }
  }

  /// Obtener label por rol
  static String getRoleLabel(String role) {
    switch (role) {
      case roleAdminGeneral: return 'Administrador General';
      case roleUserGeneral:  return 'Secretaría de Turismo';
      case roleUserPlace:    return 'Propietario de Lugar';
      default:               return 'Usuario';
    }
  }

  /// Obtener emoji por tipo de lugar
  static String getPlaceTypeEmoji(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'hotel':      return '🏨';
      case 'restaurant': return '🍽️';
      case 'bar':        return '🍹';
      default:           return '📍';
    }
  }

  /// Formatear fecha
  static String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  /// Formatear fecha y hora
  static String formatDateTime(DateTime? date) {
    if (date == null) return 'N/A';
    return '${formatDate(date)} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}