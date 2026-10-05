import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/neon_background.dart';
import '../../domain/entities/record_item.dart';
import '../../domain/entities/resource_spec.dart';
import '../providers/records_providers.dart';
import '../widgets/record_form.dart';
import '../widgets/resource_icons.dart';

class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key, required this.resourceKey});

  final String resourceKey;

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  String _query = '';

  ResourceSpec get _spec => specFor(widget.resourceKey);

  void _openForm([RecordItem? existing]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordForm(
        spec: _spec,
        existing: existing,
        onSubmit: (input) =>
            ref.read(recordsProvider(widget.resourceKey).notifier).save(input, existing: existing),
      ),
    );
  }

  String _subtitle(RecordItem item) {
    final parts = <String>[];
    for (final f in _spec.fields) {
      if (f.key == _spec.primaryField.key) continue;
      final v = item.values[f.key];
      if (v == null || v.toString().isEmpty) continue;
      final shown = f.type == FieldType.date ? v.toString().split('T').first : '$v';
      parts.add(f.type == FieldType.boolean ? (v == true ? '✓ ${f.label}' : '') : '${f.label}: $shown');
      if (parts.length == 2) break;
    }
    return parts.where((p) => p.isNotEmpty).join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec;
    final items = ref.watch(recordsProvider(widget.resourceKey));
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(resourceIcon(spec.icon), color: AppColors.cyan),
            const SizedBox(width: 10),
            Text(spec.title, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        backgroundColor: AppColors.cyan,
        foregroundColor: AppColors.obsidian,
        icon: const Icon(Icons.add_rounded),
        label: Text(S.add, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                  decoration: InputDecoration(hintText: S.search, prefixIcon: const Icon(Icons.search)),
                ),
              ),
              Expanded(
                child: AsyncView<List<RecordItem>>(
                  value: items,
                  onRetry: () => ref.invalidate(recordsProvider(widget.resourceKey)),
                  isEmpty: (list) => list.isEmpty,
                  emptyMessage: S.emptyList(spec.title),
                  data: (list) {
                    final filtered = _query.isEmpty
                        ? list
                        : list
                            .where((i) => i.values.values.any((v) => '$v'.toLowerCase().contains(_query)))
                            .toList();
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final title = item.values[spec.primaryField.key]?.toString() ?? spec.title;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Dismissible(
                            key: ValueKey(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: AlignmentDirectional.centerEnd,
                              padding: const EdgeInsetsDirectional.only(end: 20),
                              decoration: BoxDecoration(
                                color: AppColors.rose.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.delete_outline, color: AppColors.rose),
                            ),
                            onDismissed: (_) =>
                                ref.read(recordsProvider(widget.resourceKey).notifier).remove(item.id),
                            child: GlassContainer(
                              onTap: () => _openForm(item),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                        if (_subtitle(item).isNotEmpty)
                                          Text(
                                            _subtitle(item),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fadeIn(duration: 250.ms, delay: (30 * index.clamp(0, 10)).ms);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
