import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/json_editor_l10n.dart';
import '../schema_field_editor.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';
import 'format_support.dart';

/// A box to tick to agree to something, activated by `"x-format": "consent"`
/// on a `boolean`. The title is Markdown, so it can link to the terms:
///
/// ```json
/// {"type": "boolean", "const": true, "x-format": "consent",
///  "title": "I accept the [terms](https://example.com/terms) and the [privacy policy](https://example.com/privacy)"}
/// ```
///
/// Links open through [ConsentEditor.openLink] (the browser, by default).
/// Ticking stores `true`. When the field is required or its `const` is
/// `true`, unticking clears the value (so the form counts it as missing)
/// and shows that consent is needed; otherwise it stores `false`. The
/// description shows under the text. A schema that isn't a boolean renders
/// with the editor it would get without the `x-format`.
class ConsentEditor extends SchemaFieldEditor {
  const ConsentEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
  });

  /// Opens a link from the consent text; the platform browser by default.
  static Future<void> Function(Uri uri) openLink = (uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  State<ConsentEditor> createState() => _ConsentEditorState();
}

class _ConsentEditorState extends State<ConsentEditor> {
  /// Whether the box was unticked here, so the error shows only after that.
  bool _declined = false;

  bool get _mustAgree =>
      widget.isRequired || widget.schema.schemaMap?['const'] == true;

  void _set(bool on) {
    setState(() => _declined = !on);
    widget.onChanged(on ? true : (_mustAgree ? null : false));
  }

  @override
  Widget build(BuildContext context) {
    if (!schemaTypeNames(widget.schema).contains('boolean')) {
      return editorWithoutFormat(
        context,
        format: 'consent',
        schema: widget.schema,
        path: widget.path,
        value: widget.value,
        onChanged: widget.onChanged,
        isRequired: widget.isRequired,
        isNullable: widget.isNullable,
      );
    }
    final editorTheme =
        Theme.of(context).extension<JsonEditorTheme>() ??
        EditorThemeDefaults.fromContext(context);
    final l10n = JsonEditorL10n.of(context);
    final theme = Theme.of(context);
    final readOnly = widget.schema.readOnly == true;
    final checked = widget.value == true;
    final text = widget.schema.title ?? widget.path.split('.').last;
    final showError =
        _mustAgree && !checked && (_declined || widget.value == false);
    final textStyle = theme.textTheme.bodyMedium;

    return Padding(
      padding: editorTheme.fieldPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            key: const ValueKey('consent-checkbox'),
            value: checked,
            isError: showError,
            onChanged: readOnly ? null : (on) => _set(on == true),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: readOnly ? null : () => _set(!checked),
                    child: MarkdownBody(
                      key: const ValueKey('consent-text'),
                      data: _mustAgree ? '$text \\*' : text,
                      styleSheet: MarkdownStyleSheet(
                        p: textStyle,
                        a: textStyle?.copyWith(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      onTapLink: (text, href, title) {
                        final uri = href == null ? null : Uri.tryParse(href);
                        if (uri != null) ConsentEditor.openLink(uri);
                      },
                    ),
                  ),
                  if (widget.schema.description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.schema.description!,
                        style:
                            editorTheme.helperStyle ??
                            theme.textTheme.bodySmall,
                      ),
                    ),
                  if (showError)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.consentRequired,
                        key: const ValueKey('consent-error'),
                        style:
                            editorTheme.errorStyle ??
                            theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
