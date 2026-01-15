import 'package:asthme_app/domain/entities/user.dart';

/// Modèle User pour la couche data (avec sérialisation JSON)
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.createdAt,
  });

  /// Créer un UserModel depuis un JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convertir vers JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Créer une copie avec modifications
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
