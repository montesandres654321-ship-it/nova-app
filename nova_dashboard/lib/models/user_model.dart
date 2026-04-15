// lib/models/user_model.dart
// ✅ VERSIÓN COMPLETA Y CORREGIDA

class UserModel {
  final int id;
  final String? firstName;
  final String? lastName;
  final String username;
  final String email;
  final String? phone;
  final String? dob;
  final String? gender;
  final String? googleId;
  final bool isActive;
  final String? createdAt;
  final String? lastLogin;
  final String? role;
  final int? placeId;

  // ✅ NUEVAS PROPIEDADES para stats
  final int? totalScans;
  final int? totalRewards;
  final int? redeemedRewards;

  UserModel({
    required this.id,
    this.firstName,
    this.lastName,
    required this.username,
    required this.email,
    this.phone,
    this.dob,
    this.gender,
    this.googleId,
    this.isActive = true,
    this.createdAt,
    this.lastLogin,
    this.role,
    this.placeId,
    this.totalScans,
    this.totalRewards,
    this.redeemedRewards,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? json['firstName'],
      lastName: json['last_name'] ?? json['lastName'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      dob: json['dob'],
      gender: json['gender'],
      googleId: json['google_id'] ?? json['googleId'],
      isActive: (json['is_active'] ?? json['isActive'] ?? 1) == 1,
      createdAt: json['created_at'] ?? json['createdAt'],
      lastLogin: json['last_login'] ?? json['lastLogin'],
      role: json['role'],
      placeId: json['place_id'] ?? json['placeId'],

      // ✅ Stats del backend
      totalScans: json['total_scans'] ?? json['totalScans'],
      totalRewards: json['total_rewards'] ?? json['totalRewards'],
      redeemedRewards: json['redeemed_rewards'] ?? json['redeemedRewards'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'email': email,
      'phone': phone,
      'dob': dob,
      'gender': gender,
      'google_id': googleId,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'last_login': lastLogin,
      'role': role,
      'place_id': placeId,
      'total_scans': totalScans,
      'total_rewards': totalRewards,
      'redeemed_rewards': redeemedRewards,
    };
  }

  // ============================================
  // GETTERS
  // ============================================

  bool get isMobileUser => role == null;
  bool get isAdminGeneral => role == 'admin_general';
  bool get isUserGeneral => role == 'user_general';
  bool get isUserPlace => role == 'user_place';
  bool get isAdmin => isAdminGeneral || isUserGeneral;
  bool get hasAdminRole => role != null;

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    if (firstName != null) return firstName!;
    if (lastName != null) return lastName!;
    return username;
  }

  String get displayName {
    final name = fullName.trim();
    return name.isNotEmpty ? name : email;
  }

  String get initials {
    final name = fullName.trim();
    if (name.isEmpty) return email.substring(0, 1).toUpperCase();

    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  String get roleLabel {
    if (role == null) return 'Usuario Móvil';
    switch (role) {
      case 'admin_general':
        return 'Administrador General';
      case 'user_general':
        return 'Usuario General';
      case 'user_place':
        return 'Propietario de Lugar';
      default:
        return 'Usuario';
    }
  }

  String get roleEmoji {
    if (role == null) return '📱';
    switch (role) {
      case 'admin_general':
        return '👑';
      case 'user_general':
        return '👤';
      case 'user_place':
        return '🏪';
      default:
        return '👤';
    }
  }

  String get roleLabelWithEmoji => '$roleEmoji $roleLabel';

  String get roleColor {
    if (role == null) return '#06B6A4';
    switch (role) {
      case 'admin_general':
        return '#EF4444';
      case 'user_general':
        return '#3B82F6';
      case 'user_place':
        return '#F59E0B';
      default:
        return '#6B7280';
    }
  }

  String get statusLabel => isActive ? 'Activo' : 'Inactivo';
  String get statusEmoji => isActive ? '✅' : '❌';

  bool get isGoogleUser => googleId != null && googleId!.isNotEmpty;

  String get authMethod => isGoogleUser ? 'Google' : 'Email/Contraseña';
  String get authMethodEmoji => isGoogleUser ? '🔐 Google' : '📧 Email';

  // ✅ NUEVOS GETTERS para stats
  int get scansCount => totalScans ?? 0;
  int get rewardsCount => totalRewards ?? 0;
  int get redeemedCount => redeemedRewards ?? 0;
  int get pendingRewards => rewardsCount - redeemedCount;

  bool get hasActivity => scansCount > 0 || rewardsCount > 0;

  UserModel copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? phone,
    String? dob,
    String? gender,
    String? googleId,
    bool? isActive,
    String? createdAt,
    String? lastLogin,
    String? role,
    int? placeId,
    int? totalScans,
    int? totalRewards,
    int? redeemedRewards,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      googleId: googleId ?? this.googleId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      role: role ?? this.role,
      placeId: placeId ?? this.placeId,
      totalScans: totalScans ?? this.totalScans,
      totalRewards: totalRewards ?? this.totalRewards,
      redeemedRewards: redeemedRewards ?? this.redeemedRewards,
    );
  }

  @override
  String toString() {
    return 'UserModel{id: $id, email: $email, role: $role, isActive: $isActive}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}