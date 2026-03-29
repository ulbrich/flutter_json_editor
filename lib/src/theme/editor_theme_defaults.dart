import 'package:flutter/material.dart';

import 'editor_theme.dart';

class EditorThemeDefaults {
  static JsonEditorTheme fromContext(BuildContext context) {
    final theme = Theme.of(context);
    return JsonEditorTheme(
      fieldSpacing: 4.0,
      sectionSpacing: 8.0,
      fieldPadding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 2.0),
      labelStyle: theme.textTheme.bodyMedium,
      errorStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.error,
      ),
      helperStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      requiredIndicatorColor: theme.colorScheme.error,
    );
  }
}
