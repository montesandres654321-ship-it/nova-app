class ScanRecord {
  final String place;
  final DateTime time;
  final String? code;

  ScanRecord({required this.place, required this.time, this.code});

  factory ScanRecord.fromMap(Map<String, dynamic> map) {
    return ScanRecord(
      place: map['lugar'],
      time: DateTime.parse(map['created_at']),
      code: map['qrCode'], // ✅ REMOVIDO: ?? null (era redundante)
    );
  }
}