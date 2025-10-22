// lib/pages/scan_record.dart - VERSIÓN CORREGIDA
class ScanRecord {
  final int id;
  final String place;
  final String type;
  final String local;
  final DateTime time;
  final String? code;

  ScanRecord({
    required this.id,
    required this.place,
    required this.type,
    required this.local,
    required this.time,
    this.code,
  });

  factory ScanRecord.fromMap(Map<String, dynamic> map) {
    return ScanRecord(
      id: map['scan_id'] ?? 0,
      place: map['lugar'] ?? 'Lugar desconocido',
      type: map['tipo'] ?? 'Tipo desconocido',
      local: map['local'] ?? 'Local desconocido',
      time: DateTime.parse(map['created_at']),
      code: map['qrCode'],
    );
  }

  @override
  String toString() {
    return 'ScanRecord{id: $id, place: $place, type: $type, local: $local, time: $time}';
  }
}