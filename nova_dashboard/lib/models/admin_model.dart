// lib/models/admin_model.dart - MODELO COMPLETO

class AdminModel {
  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? phone;
  final String role; // 'admin_general', 'user_general', 'user_place'
  final int? placeId;
  final String? placeName;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  AdminModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.phone,
    required this.role,
    this.placeId,
    this.placeName,
    required this.isActive,
    this.createdAt,
    this.lastLogin,
  });

  // ============================================
  // GETTERS DERIVADOS - ✅ AGREGADOS
  // ============================================

  /// Nombre completo del admin
  String get fullName => '$firstName $lastName';

  /// ✅ AGREGADO: Nombre para mostrar (alias de fullName)
  String get displayName => fullName;

  /// Verificar si tiene lugar asignado
  bool get hasPlace => placeId != null;

  /// ✅ AGREGADO: Emoji según el rol
  String get roleEmoji {
    switch (role) {
      case 'admin_general':
        return '👑';
      case 'user_general':
        return '📋';
      case 'user_place':
        return '🏪';
      default:
        return '👤';
    }
  }

  /// ✅ AGREGADO: Label del rol
  String get roleLabel {
    switch (role) {
      case 'admin_general':
        return 'Admin General';
      case 'user_general':
        return 'Usuario General';
      case 'user_place':
        return 'Propietario';
      default:
        return 'Usuario';
    }
  }

  /// Es admin general
  bool get isAdminGeneral => role == 'admin_general';

  /// Es usuario general
  bool get isUserGeneral => role == 'user_general';

  /// Es propietario
  bool get isUserPlace => role == 'user_place';

  // ============================================
  // FACTORY
  // ============================================

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      id: json['id'] as int,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      username: json['username'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      placeId: json['place_id'] as int?,
      placeName: json['place_name'] as String?,
      isActive: (json['is_active'] == 1 || json['is_active'] == true),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      lastLogin: json['last_login'] != null
          ? DateTime.tryParse(json['last_login'])
          : null,
    );
  }

  // ============================================
  // TO JSON
  // ============================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'email': email,
      'phone': phone,
      'role': role,
      'place_id': placeId,
      'place_name': placeName,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  // ============================================
  // COPY WITH
  // ============================================

  AdminModel copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? phone,
    String? role,
    int? placeId,
    String? placeName,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return AdminModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      placeId: placeId ?? this.placeId,
      placeName: placeName ?? this.placeName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}