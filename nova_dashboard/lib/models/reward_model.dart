// lib/models/reward_model.dart
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

  // Crear desde JSON
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
      email: json['email'],
      placeName: json['place_name'],
      placeType: json['place_type'],
      lugar: json['lugar'],
    );
  }

  // Convertir a JSON
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

  // ============================================
  // GETTERS Y MÉTODOS ÚTILES
  // ============================================

  /// Verificar si está canjeada
  bool get isRedeemedBool => isRedeemed == 1;

  /// Nombre completo del usuario
  String get userFullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName'.trim();
    }
    return email ?? 'Usuario desconocido';
  }

  /// Copiar con cambios
  RewardModel copyWith({
    int? id,
    int? userId,
    int? placeId,
    String? rewardName,
    String? rewardDescription,
    String? rewardIcon,
    String? earnedAt,
    int? isRedeemed,
    String? redeemedAt,
    String? firstName,
    String? lastName,
    String? email,
    String? placeName,
    String? placeType,
    String? lugar,
  }) {
    return RewardModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      placeId: placeId ?? this.placeId,
      rewardName: rewardName ?? this.rewardName,
      rewardDescription: rewardDescription ?? this.rewardDescription,
      rewardIcon: rewardIcon ?? this.rewardIcon,
      earnedAt: earnedAt ?? this.earnedAt,
      isRedeemed: isRedeemed ?? this.isRedeemed,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      placeName: placeName ?? this.placeName,
      placeType: placeType ?? this.placeType,
      lugar: lugar ?? this.lugar,
    );
  }

  @override
  String toString() {
    return 'RewardModel(id: $id, user: $userFullName, place: $placeName, redeemed: $isRedeemedBool)';
  }
}