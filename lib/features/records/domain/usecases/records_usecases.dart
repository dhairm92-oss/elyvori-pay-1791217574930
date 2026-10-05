import '../../../../core/error/failure.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/result/result.dart';
import '../entities/record_item.dart';
import '../entities/resource_spec.dart';
import '../repositories/records_repository.dart';

/// Validates and normalises raw form input against the module's fields.
class ValidateRecord {
  const ValidateRecord();

  Result<Map<String, Object?>> call(ResourceSpec spec, Map<String, String> input) {
    final values = <String, Object?>{};
    for (final field in spec.fields) {
      final raw = (input[field.key] ?? '').trim();
      if (raw.isEmpty) {
        if (field.required && field.type != FieldType.boolean) {
          return Result.failure(Failure(S.requiredField(field.label)));
        }
        values[field.key] = field.type == FieldType.boolean ? false : null;
        continue;
      }
      switch (field.type) {
        case FieldType.number:
          final n = num.tryParse(raw.replaceAll(',', '.'));
          if (n == null) return Result.failure(Failure(S.mustBeNumber(field.label)));
          values[field.key] = n;
        case FieldType.boolean:
          values[field.key] = raw == 'true';
        case FieldType.date:
          final d = DateTime.tryParse(raw);
          if (d == null) return Result.failure(Failure(S.mustBeDate(field.label)));
          values[field.key] = d.toIso8601String();
        case FieldType.email:
          if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(raw)) {
            return Result.failure(Failure(S.mustBeEmail(field.label)));
          }
          values[field.key] = raw.toLowerCase();
        case FieldType.phone:
          if (!RegExp(r'^\+?[0-9 ()\-]{6,20}$').hasMatch(raw)) {
            return Result.failure(Failure(S.mustBePhone(field.label)));
          }
          values[field.key] = raw;
        case FieldType.text:
        case FieldType.longText:
          values[field.key] = raw;
      }
    }
    return Result.success(values);
  }
}

class SaveRecord {
  const SaveRecord(this._repository, [this._validate = const ValidateRecord()]);

  final RecordsRepository _repository;
  final ValidateRecord _validate;

  Future<Result<RecordItem>> call(ResourceSpec spec, Map<String, String> input, {RecordItem? existing}) async {
    final validated = _validate(spec, input);
    return validated.when(
      failure: (f) async => Result<RecordItem>.failure(f),
      success: (values) {
        final now = DateTime.now();
        final item = existing?.copyWith(values: values, synced: false, updatedAt: now) ??
            RecordItem(id: '${spec.key}_${now.microsecondsSinceEpoch}', createdAt: now, values: values);
        return _repository.save(spec, item);
      },
    );
  }
}
