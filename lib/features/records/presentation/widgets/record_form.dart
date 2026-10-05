import 'package:flutter/material.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/neon_button.dart';
import '../../domain/entities/record_item.dart';
import '../../domain/entities/resource_spec.dart';

/// Form generated from the module's fields. Returns raw input through [onSubmit].
class RecordForm extends StatefulWidget {
  const RecordForm({super.key, required this.spec, required this.onSubmit, this.existing});

  final ResourceSpec spec;
  final RecordItem? existing;
  final Future<String?> Function(Map<String, String> input) onSubmit;

  @override
  State<RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends State<RecordForm> {
  late final Map<String, TextEditingController> _controllers = {
    for (final f in widget.spec.fields)
      f.key: TextEditingController(text: _initial(f)),
  };
  late final Map<String, bool> _switches = {
    for (final f in widget.spec.fields.where((f) => f.type == FieldType.boolean))
      f.key: widget.existing?.values[f.key] == true,
  };
  bool _saving = false;
  String? _error;

  String _initial(FieldSpec f) {
    final v = widget.existing?.values[f.key];
    if (v == null) return '';
    if (f.type == FieldType.date) return v.toString().split('T').first;
    return v.toString();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(FieldSpec field) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 50),
      lastDate: DateTime(now.year + 10),
      initialDate: DateTime.tryParse(_controllers[field.key]!.text) ?? now,
    );
    if (picked != null) {
      setState(() => _controllers[field.key]!.text = picked.toIso8601String().split('T').first);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final input = <String, String>{
      for (final f in widget.spec.fields)
        f.key: f.type == FieldType.boolean ? '${_switches[f.key] ?? false}' : _controllers[f.key]!.text,
    };
    final error = await widget.onSubmit(input);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  Widget _field(FieldSpec f) {
    final label = f.required ? '${f.label} *' : f.label;
    switch (f.type) {
      case FieldType.boolean:
        return SwitchListTile(
          value: _switches[f.key] ?? false,
          title: Text(f.label),
          activeColor: AppColors.cyan,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => setState(() => _switches[f.key] = v),
        );
      case FieldType.date:
        return TextField(
          controller: _controllers[f.key],
          readOnly: true,
          onTap: () => _pickDate(f),
          decoration: InputDecoration(hintText: label, prefixIcon: const Icon(Icons.event)),
        );
      case FieldType.number:
        return TextField(
          controller: _controllers[f.key],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(hintText: label),
        );
      case FieldType.phone:
        return TextField(
          controller: _controllers[f.key],
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(hintText: label, prefixIcon: const Icon(Icons.phone)),
        );
      case FieldType.email:
        return TextField(
          controller: _controllers[f.key],
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: InputDecoration(hintText: label, prefixIcon: const Icon(Icons.alternate_email)),
        );
      case FieldType.longText:
        return TextField(
          controller: _controllers[f.key],
          minLines: 3,
          maxLines: 6,
          decoration: InputDecoration(hintText: label),
        );
      case FieldType.text:
        return TextField(controller: _controllers[f.key], decoration: InputDecoration(hintText: label));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: GlassContainer(
        radius: 24,
        blur: 24,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null ? S.newRecord(widget.spec.title) : S.editRecord(widget.spec.title),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              for (final f in widget.spec.fields) ...[_field(f), const SizedBox(height: 10)],
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: AppColors.rose)),
                const SizedBox(height: 10),
              ],
              NeonButton(label: S.save, icon: Icons.check_rounded, loading: _saving, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
