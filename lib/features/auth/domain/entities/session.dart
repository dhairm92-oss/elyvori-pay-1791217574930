import 'package:equatable/equatable.dart';

class Session extends Equatable {
  const Session({required this.email, this.name, this.organizationName});

  final String email;
  final String? name;
  final String? organizationName;

  @override
  List<Object?> get props => [email, name, organizationName];
}
