import 'package:flutter/material.dart';
import 'package:json_schema/json_schema.dart';

/// Renders a standalone JSON Schema `const` as a read-only field.
///
/// A `const` fixes the value to exactly one constant, so there is nothing to
/// edit — the constant is shown for context (labelled by `title`, described by
/// `description`). Value storage is unchanged; authoring data should already
/// carry the constant.
class ConstEditor extends StatelessWidget {
  final JsonSchema schema;
  final String path;
  final dynamic value;
  final void Function(dynamic) onChanged;
  final bool isRequired;
  final bool isNullable;

  const ConstEditor({
    super.key,
    required this.schema,
    required this.path,
    required this.value,
    required this.onChanged,
    required this.isRequired,
    this.isNullable = false,
  });

  String get _label {
    final base = schema.title ?? path.split('.').last;
    return isRequired ? '$base *' : base;
  }

  @override
  Widget build(BuildContext context) {
    final constValue = schema.schemaMap?['const'];
    return InputDecorator(
      decoration: InputDecoration(
        labelText: _label,
        helperText: schema.description,
        enabled: false,
      ),
      child: Text(
        constValue?.toString() ?? '',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
