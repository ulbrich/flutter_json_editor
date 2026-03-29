import 'package:json_schema/json_schema.dart';

class ValidationHelper {
  /// Mode 1: Sub-schema field validation.
  /// Validates [value] against [schema] directly.
  static List<String> validateField(JsonSchema schema, dynamic value) {
    if (value == null) return [];
    final results = schema.validate(value);
    return results.errors.map((e) => e.message).toList();
  }

  /// Mode 2: Parent-context validation (for required, cross-field).
  /// Validates [fullParentObject] against [parentSchema] and filters errors
  /// relevant to [fieldPath].
  static List<String> validateInParentContext(
    JsonSchema parentSchema,
    Map<String, dynamic> fullParentObject,
    String fieldPath,
  ) {
    final results = parentSchema.validate(fullParentObject);
    return results.errors
        .where((e) => e.instancePath == '/$fieldPath')
        .map((e) => e.message)
        .toList();
  }
}
