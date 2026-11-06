import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

import '../l10n/json_editor_l10n.dart';
import '../l10n/validation_l10n.dart';
import '../schema_field_editor.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';
import '../validation_helper.dart';
import 'format_support.dart';

/// A picture stored in the data itself as base64, activated by
/// `"x-format": "image-data"` on a `string` schema. The picture comes from
/// the photo library (or a file chooser on desktop and web) or, where the
/// platform has one, the camera:
///
/// ```json
/// {"type": "string", "title": "Photo", "x-format": "image-data",
///  "x-max-width": 800, "x-max-height": 800, "x-image-quality": 80}
/// ```
///
/// The value is a data URI (`data:image/jpeg;base64,…`), or plain base64
/// when the schema says so with the standard `"contentEncoding": "base64"`.
/// Both forms are read either way. Pictures are scaled down while picking to
/// fit `x-max-width` × `x-max-height` (default
/// [ImageDataEditor.defaultMaxDimension]) and re-encoded with
/// `x-image-quality` (default [ImageDataEditor.defaultImageQuality]),
/// because every byte ends up in the JSON; `maxLength` limits the encoded
/// string. A schema that isn't a string renders with the editor it would get
/// without the `x-format`.
///
/// Picking uses the `image_picker` plugin, so apps need its platform setup:
/// `NSPhotoLibraryUsageDescription` and `NSCameraUsageDescription` on iOS,
/// the `com.apple.security.files.user-selected.read-only` entitlement on
/// macOS.
class ImageDataEditor extends SchemaFieldEditor {
  const ImageDataEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
  });

  /// Longest side, in pixels, of a picked picture without `x-max-width` and
  /// `x-max-height`.
  static const int defaultMaxDimension = 1024;

  /// Encoding quality (0–100) of a picked picture without `x-image-quality`.
  static const int defaultImageQuality = 85;

  /// The bytes of a data URI or plain (standard or URL-safe, padded or not)
  /// base64; null when [value] is neither or empty.
  static Uint8List? decode(String? value) {
    if (value == null) return null;
    var text = value.trim();
    if (text.startsWith('data:')) {
      final comma = text.indexOf(',');
      if (comma < 0 || !text.substring(0, comma).endsWith(';base64')) {
        return null;
      }
      text = text.substring(comma + 1);
    }
    text = text.replaceAll(RegExp(r'\s'), '');
    if (text.isEmpty) return null;
    try {
      return base64.decode(base64.normalize(text));
    } on FormatException {
      return null;
    }
  }

  /// The MIME type of image [bytes] by their signature (JPEG, PNG, GIF,
  /// WebP, HEIC, BMP); null for anything else.
  static String? mimeTypeOf(Uint8List bytes) {
    bool startsWith(List<int> signature, [int offset = 0]) {
      if (bytes.length < offset + signature.length) return false;
      for (var i = 0; i < signature.length; i++) {
        if (bytes[offset + i] != signature[i]) return false;
      }
      return true;
    }

    if (startsWith([0xFF, 0xD8, 0xFF])) return 'image/jpeg';
    if (startsWith([0x89, 0x50, 0x4E, 0x47])) return 'image/png';
    if (startsWith(ascii.encode('GIF8'))) return 'image/gif';
    if (startsWith(ascii.encode('RIFF')) &&
        startsWith(ascii.encode('WEBP'), 8)) {
      return 'image/webp';
    }
    if (startsWith(ascii.encode('ftyp'), 4) &&
        [
          'heic',
          'heix',
          'heif',
          'mif1',
        ].any((brand) => startsWith(ascii.encode(brand), 8))) {
      return 'image/heic';
    }
    if (startsWith(ascii.encode('BM'))) return 'image/bmp';
    return null;
  }

  /// [bytes] as a data URI, or as plain base64 when [dataUri] is false. The
  /// type comes from the bytes, else [mimeType], else
  /// `application/octet-stream`.
  static String encode(
    Uint8List bytes, {
    bool dataUri = true,
    String? mimeType,
  }) {
    final data = base64.encode(bytes);
    if (!dataUri) return data;
    final type = mimeTypeOf(bytes) ?? mimeType ?? 'application/octet-stream';
    return 'data:$type;base64,$data';
  }

  @override
  State<ImageDataEditor> createState() => _ImageDataEditorState();
}

class _ImageDataEditorState extends State<ImageDataEditor> {
  final ImagePicker _picker = ImagePicker();
  bool _busy = false;
  String? _pickError;

  /// [_bytes] decoded from [_decodedFrom], so a rebuild doesn't decode (and
  /// [Image.memory] doesn't reload) the same picture again.
  String? _decodedFrom;
  Uint8List? _bytes;

  Uint8List? get _currentBytes {
    final value = widget.value is String ? widget.value as String : null;
    if (value != _decodedFrom) {
      _decodedFrom = value;
      _bytes = ImageDataEditor.decode(value);
    }
    return _bytes;
  }

  Map<dynamic, dynamic> get _schemaMap =>
      widget.schema.schemaMap ?? const <String, dynamic>{};

  bool get _storesDataUri => _schemaMap['contentEncoding'] != 'base64';

  double _dimension(String key) {
    final value = _schemaMap[key];
    if (value is num && value > 0) return value.toDouble();
    return ImageDataEditor.defaultMaxDimension.toDouble();
  }

  int get _quality {
    final value = _schemaMap['x-image-quality'];
    return value is num
        ? value.round().clamp(0, 100)
        : ImageDataEditor.defaultImageQuality;
  }

  bool get _cameraSupported {
    try {
      return _picker.supportsImageSource(ImageSource.camera);
    } catch (_) {
      return false;
    }
  }

  Future<void> _pick(ImageSource source) async {
    final failed = JsonEditorL10n.of(context).imagePickFailed;
    setState(() {
      _busy = true;
      _pickError = null;
    });
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: _dimension('x-max-width'),
        maxHeight: _dimension('x-max-height'),
        imageQuality: _quality,
        requestFullMetadata: false,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      widget.onChanged(
        ImageDataEditor.encode(
          bytes,
          dataUri: _storesDataUri,
          mimeType: file.mimeType,
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _pickError = failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _describe(Uint8List bytes) {
    final type = ImageDataEditor.mimeTypeOf(bytes)?.split('/').last;
    final kb = bytes.length / 1024;
    final size = kb < 1024
        ? '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB'
        : '${(kb / 1024).toStringAsFixed(1)} MB';
    return [if (type != null) type.toUpperCase(), size].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    if (!schemaTypeNames(widget.schema).contains('string')) {
      return editorWithoutFormat(
        context,
        format: 'image-data',
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
    final bytes = _currentBytes;
    final hasValue =
        widget.value is String && (widget.value as String).isNotEmpty;
    final invalid = hasValue && bytes == null;
    final errors = hasValue
        ? ValidationHelper.validateField(widget.schema, widget.value)
        : const <String>[];
    final shape = BorderRadius.circular(8);

    final preview = bytes == null
        ? Container(
            key: const ValueKey('image-data-placeholder'),
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: shape,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.image_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ClipRRect(
                  borderRadius: shape,
                  child: Image.memory(
                    bytes,
                    key: const ValueKey('image-data-preview'),
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120,
                      color: theme.colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 40,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _describe(bytes),
                key: const ValueKey('image-data-info'),
                style: editorTheme.helperStyle ?? theme.textTheme.bodySmall,
              ),
            ],
          );

    return FormatFieldFrame(
      label: fieldLabel(widget.schema, widget.path, widget.isRequired),
      description: widget.schema.description,
      editorTheme: editorTheme,
      errorText:
          _pickError ??
          (invalid ? l10n.invalidImageData : null) ??
          localizeFirstValidationError(l10n, errors),
      trailing: readOnly || !hasValue
          ? null
          : [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.removeImageTooltip,
                onPressed: _busy ? null : () => widget.onChanged(null),
              ),
            ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          preview,
          if (!readOnly) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(l10n.choosePictureLabel),
                  onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                ),
                if (_cameraSupported)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(l10n.takePhotoLabel),
                    onPressed: _busy ? null : () => _pick(ImageSource.camera),
                  ),
                if (_busy)
                  const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
