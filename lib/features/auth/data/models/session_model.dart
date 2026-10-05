import '../../domain/entities/session.dart';

class SessionModel extends Session {
  const SessionModel({required super.email, super.name, super.organizationName});

  factory SessionModel.fromLoginJson(Map<String, dynamic> json) {
    final user = json['user'];
    final map = user is Map<String, dynamic> ? user : const <String, dynamic>{};
    return SessionModel(
      email: (map['email'] as String?) ?? '',
      name: map['name'] as String?,
      organizationName: map['organizationName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {'email': email, 'name': name, 'organizationName': organizationName};

  factory SessionModel.fromJson(Map<String, dynamic> json) => SessionModel(
        email: (json['email'] as String?) ?? '',
        name: json['name'] as String?,
        organizationName: json['organizationName'] as String?,
      );
}
