// lib/models/scan_record.dart
// ============================================================
// MODELO DE REGISTRO DE ESCANEO — Nova App Móvil
// ============================================================
// Mapea la respuesta de GET /scans/details/:userId
// Backend v6.0 devuelve: id, created_at, place_id, place_name,
//   place_tipo, place_lugar, place_image, place_rating,
//   has_reward, reward_name
// ============================================================

class ScanRecord {
  final int id;
  final String place;   // lugar geográfico (Coveñas, Tolú, etc.)
  final String type;    // tipo (hotel, restaurant, bar)
  final String local;   // nombre del establecimiento
  final DateTime time;  // fecha del escaneo
  final String? code;   // código QR original
  final String? image;  // imagen del lugar
  final bool hasReward;
  final String? rewardName;

  ScanRecord({
    required this.id,
    required this.place,
    required this.type,
    required this.local,
    required this.time,
    this.code,
    this.image,
    this.hasReward = false,
    this.rewardName,
  });

  factory ScanRecord.fromMap(Map<String, dynamic> map) {
    // Parseo robusto de fecha
    DateTime parsedTime;
    try {
      parsedTime = DateTime.parse(map['created_at'] ?? '');
    } catch (_) {
      parsedTime = DateTime.now();
    }

    return ScanRecord(
      id: map['id'] ?? map['scan_id'] ?? 0,
      // Backend v6.0: place_lugar, fallback a lugar
      place: map['place_lugar'] ?? map['lugar'] ?? 'Lugar desconocido',
      // Backend v6.0: place_tipo, fallback a tipo
      type: map['place_tipo'] ?? map['tipo'] ?? 'desconocido',
      // Backend v6.0: place_name, fallback a local/name
      local: map['place_name'] ?? map['local'] ?? map['name'] ?? 'Establecimiento',
      time: parsedTime,
      code: map['qrCode'] ?? map['qr_code'],
      image: map['place_image'] ?? map['image_url'],
      hasReward: map['has_reward'] == 1 || map['has_reward'] == true,
      rewardName: map['reward_name'],
    );
  }

  @override
  String toString() => 'ScanRecord{id: $id, local: $local, type: $type, place: $place}';
}