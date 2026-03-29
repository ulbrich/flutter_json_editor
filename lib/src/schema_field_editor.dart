import 'package:flutter/widgets.dart';
import 'package:json_schema/json_schema.dart';

typedef SchemaFieldEditorBuilder = Widget Function({
  required JsonSchema schema,
  required String path,
  required dynamic value,
  required void Function(dynamic value) onChanged,
  required bool isRequired,
  bool isNullable,
});

abstract class SchemaFieldEditor extends StatefulWidget {
  final JsonSchema schema;
  final String path;
  final dynamic value;
  final void Function(dynamic value) onChanged;
  final bool isRequired;
  final bool isNullable;

  const SchemaFieldEditor({
    super.key,
    required this.schema,
    required this.path,
    required this.value,
    required this.onChanged,
    required this.isRequired,
    this.isNullable = false,
  });
}
