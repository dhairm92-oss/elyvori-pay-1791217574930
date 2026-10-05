import 'package:equatable/equatable.dart';

enum FieldType { text, longText, number, boolean, date, phone, email }

/// One input of a module (e.g. "price", number, required).
class FieldSpec extends Equatable {
  const FieldSpec({required this.key, required this.label, this.type = FieldType.text, this.required = false});

  final String key;
  final String label;
  final FieldType type;
  final bool required;

  @override
  List<Object?> get props => [key, label, type, required];
}

/// A module of the app (e.g. "Orders", "Bookings") described as data, so new
/// modules never need new code: list, search, add, edit and delete come free.
class ResourceSpec extends Equatable {
  const ResourceSpec({
    required this.key,
    required this.title,
    required this.fields,
    this.icon = 'grid',
    this.description = '',
  });

  final String key;
  final String title;
  final String description;
  final String icon;
  final List<FieldSpec> fields;

  /// The field shown as the title of each row.
  FieldSpec get primaryField => fields.firstWhere(
        (f) => f.type == FieldType.text,
        orElse: () => fields.isNotEmpty ? fields.first : const FieldSpec(key: 'name', label: 'Name'),
      );

  @override
  List<Object?> get props => [key, title, description, icon, fields];
}
