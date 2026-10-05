import '../../../../core/result/result.dart';
import '../entities/record_item.dart';
import '../entities/resource_spec.dart';

abstract interface class RecordsRepository {
  Future<Result<List<RecordItem>>> list(ResourceSpec spec);
  Future<Result<RecordItem>> save(ResourceSpec spec, RecordItem item);
  Future<Result<bool>> delete(ResourceSpec spec, String id);
}
