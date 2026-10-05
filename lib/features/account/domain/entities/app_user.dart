import 'package:equatable/equatable.dart';

/// The person signed in to this app (its own accounts, not Elyvori's).
class AppUser extends Equatable {
  const AppUser({required this.id, required this.email, this.name, this.provider = 'password'});

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String? ?? '',
        email: json['email'] as String? ?? '',
        name: json['name'] as String?,
        provider: json['provider'] as String? ?? 'password',
      );

  final String id;
  final String email;
  final String? name;
  final String provider;

  /// "Sara" for "Sara Ahmad", or the part before @ when there is no name.
  String get displayName {
    final n = name?.trim() ?? '';
    if (n.isNotEmpty) return n;
    final at = email.indexOf('@');
    return at > 0 ? email.substring(0, at) : email;
  }

  String get firstName => displayName.split(RegExp(r'\s+')).first;

  /// One or two letters for the avatar.
  String get initials {
    final parts = displayName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = String.fromCharCode(parts.first.runes.first);
    if (parts.length == 1) return first.toUpperCase();
    return (first + String.fromCharCode(parts.last.runes.first)).toUpperCase();
  }

  AppUser copyWith({String? name}) => AppUser(id: id, email: email, name: name ?? this.name, provider: provider);

  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'name': name, 'provider': provider};

  @override
  List<Object?> get props => [id, email, name, provider];
}
