// lib/models/reward_model.dart
// ============================================================
// FIX: leer user_email (backend devuelve u.email AS user_email)
// FIX: leer place_tipo (backend devuelve p.tipo AS place_tipo)
// FIX: leer place_lugar (backend devuelve p.lugar AS place_lugar)
// ============================================================

class RewardModel {
  final int id;
  final int userId;
  final int placeId;
  final String rewardName;
  final String? rewardDescription;
  final String? rewardIcon;
  final String earnedAt;
  final int isRedeemed;
  final String? redeemedAt;

  // Datos relacionados (joins)
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? placeName;
  final String? placeType;
  final String? lugar;

  RewardModel({
    required this.id,
    required this.userId,
    required this.placeId,
    required this.rewardName,
    this.rewardDescription,
    this.rewardIcon,
    required this.earnedAt,
    this.isRedeemed = 0,
    this.redeemedAt,
    this.firstName,
    this.lastName,
    this.email,
    this.placeName,
    this.placeType,
    this.lugar,
  });

  factory RewardModel.fromJson(Map<String, dynamic> json) {
    return RewardModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      placeId: json['place_id'] ?? 0,
      rewardName: json['reward_name'] ?? '',
      rewardDescription: json['reward_description'],
      rewardIcon: json['reward_icon'],
      earnedAt: json['earned_at'] ?? '',
      isRedeemed: json['is_redeemed'] ?? 0,
      redeemedAt: json['redeemed_at'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      // FIX: backend devuelve u.email AS user_email
      email: json['user_email'] ?? json['email'],
      placeName: json['place_name'],
      // FIX: backend devuelve p.tipo AS place_tipo
      placeType: json['place_tipo'] ?? json['place_type'],
      // FIX: backend devuelve p.lugar AS place_lugar
      lugar: json['place_lugar'] ?? json['lugar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'place_id': placeId,
      'reward_name': rewardName,
      'reward_description': rewardDescription,
      'reward_icon': rewardIcon,
      'earned_at': earnedAt,
      'is_redeemed': isRedeemed,
      'redeemed_at': redeemedAt,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'place_name': placeName,
      'place_type': placeType,
      'lugar': lugar,
    };
  }

  bool get isRedeemedBool => isRedeemed == 1;

  String get userFullName {
    final name = [firstName, lastName]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ')
        .trim();
    if (name.isNotEmpty) return name;
    return email ?? 'Usuario desconocido';
  }

  RewardModel copyWith({
    int? id, int? userId, int? placeId, String? rewardName,
    String? rewardDescription, String? rewardIcon, String? earnedAt,
    int? isRedeemed, String? redeemedAt, String? firstName,
    String? lastName, String? email, String? placeName,
    String? placeType, String? lugar,
  }) {
    return RewardModel(
      id: id ?? this.id, userId: userId ?? this.userId,
      placeId: placeId ?? this.placeId, rewardName: rewardName ?? this.rewardName,
      rewardDescription: rewardDescription ?? this.rewardDescription,
      rewardIcon: rewardIcon ?? this.rewardIcon, earnedAt: earnedAt ?? this.earnedAt,
      isRedeemed: isRedeemed ?? this.isRedeemed, redeemedAt: redeemedAt ?? this.redeemedAt,
      firstName: firstName ?? this.firstName, lastName: lastName ?? this.lastName,
      email: email ?? this.email, placeName: placeName ?? this.placeName,
      placeType: placeType ?? this.placeType, lugar: lugar ?? this.lugar,
    );
  }

  @override
  String toString() => 'RewardModel(id: $id, user: $userFullName, place: $placeName, redeemed: $isRedeemedBool)';
}