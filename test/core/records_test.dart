import 'package:flutter_test/flutter_test.dart';

import '../../lib/core/storage/key_value_store.dart';
import '../../lib/features/records/data/datasources/records_local_data_source.dart';
import '../../lib/features/records/data/repositories/records_repository_impl.dart';
import '../../lib/features/records/domain/entities/resource_spec.dart';
import '../../lib/features/records/domain/usecases/records_usecases.dart';
import '../../lib/features/registry.dart';

const _spec = ResourceSpec(
  key: 'orders',
  title: 'Orders',
  fields: [
    FieldSpec(key: 'customer', label: 'Customer', required: true),
    FieldSpec(key: 'total', label: 'Total', type: FieldType.number, required: true),
    FieldSpec(key: 'paid', label: 'Paid', type: FieldType.boolean),
    FieldSpec(key: 'email', label: 'Email', type: FieldType.email),
  ],
);

void main() {
  test('validation rejects missing required fields and bad numbers', () {
    const validate = ValidateRecord();
    expect(validate(_spec, {'total': '5'}).isSuccess, isFalse);
    expect(validate(_spec, {'customer': 'Ali', 'total': 'abc'}).isSuccess, isFalse);
    expect(validate(_spec, {'customer': 'Ali', 'total': '5', 'email': 'nope'}).isSuccess, isFalse);
    final ok = validate(_spec, {'customer': ' Ali ', 'total': '12,5', 'paid': 'true', 'email': 'A@B.co'});
    final values = ok.getOrElse((_) => const {});
    expect(values['customer'], 'Ali');
    expect(values['total'], 12.5);
    expect(values['paid'], isTrue);
    expect(values['email'], 'a@b.co');
  });

  test('save, edit, list newest first, and delete work offline', () async {
    final store = MemoryKeyValueStore();
    final local = RecordsLocalDataSource(store);
    final repo = RecordsRepositoryImpl(local: local, trackDeletes: true);
    final save = SaveRecord(repo);

    final first = (await save(_spec, {'customer': 'Ali', 'total': '10'})).getOrElse((f) => fail(f.message));
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await save(_spec, {'customer': 'Sara', 'total': '20'});
    final edited = (await save(_spec, {'customer': 'Ali Updated', 'total': '11'}, existing: first))
        .getOrElse((f) => fail(f.message));

    final list = (await repo.list(_spec)).getOrElse((_) => const []);
    expect(list.map((i) => i.values['customer']), ['Sara', 'Ali Updated']);
    expect(list.every((i) => !i.synced), isTrue);
    expect(edited.updatedAt.isBefore(first.updatedAt), isFalse);

    await repo.delete(_spec, first.id);
    final after = (await repo.list(_spec)).getOrElse((_) => const []);
    expect(after.single.values['customer'], 'Sara');
    expect(local.readTombstones().single.id, first.id);
  });

  test('the generated registry is valid', () {
    final keys = <String>{};
    for (final r in appResources) {
      expect(r.key, matches(RegExp(r'^[a-z][a-z0-9_]*$')));
      expect(keys.add(r.key), isTrue, reason: 'duplicate module key ${r.key}');
      expect(r.fields, isNotEmpty);
      expect(r.fields.map((f) => f.key).toSet().length, r.fields.length);
    }
  });
}
