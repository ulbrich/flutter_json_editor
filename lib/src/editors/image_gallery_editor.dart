import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:json_schema/json_schema.dart';
import 'package:flutter/material.dart';

import '../l10n/json_editor_l10n.dart';
import '../l10n/validation_l10n.dart';
import '../schema_field_editor.dart';
import '../schema_utils.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';
import '../validation_helper.dart';
import 'format_support.dart';
import 'image_data_editor.dart';

/// Several pictures stored in the data as base64, activated by
/// `"x-format": "image-data"` on an `array` of strings:
///
/// ```json
/// {"type": "array", "title": "Photos", "x-format": "image-data",
///  "maxItems": 6, "x-max-width": 800,
///  "items": {"type": "string"}}
/// ```
///
/// Each item is stored like a single [ImageDataEditor] value: a data URI,
/// or plain base64 with `"contentEncoding": "base64"` on the items. The
/// pictures show as a strip of thumbnails, each with a remove button; new
/// ones come from the photo library (several at once) or the camera.
/// `x-max-width`, `x-max-height` and `x-image-quality` work as on the single
/// editor (on the array or its items); `maxItems` caps the count.
class ImageGalleryEditor extends SchemaFieldEditor {
  const ImageGalleryEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
  });

  /// Edge length of a thumbnail, in logical pixels.
  static const double thumbnailSize = 96;

  @override
  State<ImageGalleryEditor> createState() => _ImageGalleryEditorState();
}

class _ImageGalleryEditorState extends State<ImageGalleryEditor> {
  final ImagePicker _picker = ImagePicker();
  bool _busy = false;
  String? _pickError;

  /// Decoded thumbnails by their stored string, so rebuilds don't decode
  /// (and [Image.memory] doesn't reload) them again.
  final Map<String, Uint8List?> _decoded = {};

  JsonSchema? get _items => widget.schema.items == null
      ? null
      : SchemaUtils.resolveRef(widget.schema.items!);

  dynamic _option(String key) =>
      widget.schema.schemaMap?[key] ?? _items?.schemaMap?[key];

  List<String> get _images => widget.value is List
      ? [
          for (final v in widget.value as List)
            if (v is String) v,
        ]
      : <String>[];

  Uint8List? _bytes(String value) =>
      _decoded.putIfAbsent(value, () => ImageDataEditor.decode(value));

  double _dimension(String key) {
    final value = _option(key);
    if (value is num && value > 0) return value.toDouble();
    return ImageDataEditor.defaultMaxDimension.toDouble();
  }

  int get _quality {
    final value = _option('x-image-quality');
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

  Future<void> _pick(ImageSource source, int room) async {
    final failed = JsonEditorL10n.of(context).imagePickFailed;
    setState(() {
      _busy = true;
      _pickError = null;
    });
    try {
      final maxWidth = _dimension('x-max-width');
      final maxHeight = _dimension('x-max-height');
      final List<XFile> files;
      if (source == ImageSource.camera || room == 1) {
        final file = await _picker.pickImage(
          source: source,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: _quality,
          requestFullMetadata: false,
        );
        files = file == null ? const [] : [file];
      } else {
        files = await _picker.pickMultiImage(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: _quality,
          limit: room > 1 && room < 1000 ? room : null,
          requestFullMetadata: false,
        );
      }
      if (files.isEmpty) return;
      final dataUri = _option('contentEncoding') != 'base64';
      final added = [
        for (final file in files.take(room))
          ImageDataEditor.encode(
            await file.readAsBytes(),
            dataUri: dataUri,
            mimeType: file.mimeType,
          ),
      ];
      widget.onChanged([..._images, ...added]);
    } catch (_) {
      if (mounted) setState(() => _pickError = failed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _remove(int index) {
    final images = _images..removeAt(index);
    widget.onChanged(images.isEmpty && !widget.isRequired ? null : images);
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (!schemaTypeNames(widget.schema).contains('array') ||
        (items != null &&
            schemaTypeNames(items).isNotEmpty &&
            !schemaTypeNames(items).contains('string'))) {
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
    final scheme = theme.colorScheme;
    final readOnly = widget.schema.readOnly == true;
    final images = _images;
    _decoded.removeWhere((key, _) => !images.contains(key));
    final maxItems = widget.schema.maxItems;
    final room = maxItems == null ? 1000 : maxItems - images.length;
    final invalid = images.any((i) => _bytes(i) == null);
    final errors = images.isEmpty
        ? const <String>[]
        : ValidationHelper.validateField(widget.schema, images);
    const size = ImageGalleryEditor.thumbnailSize;
    final shape = BorderRadius.circular(8);

    Widget thumbnail(int index) {
      final bytes = _bytes(images[index]);
      return SizedBox.square(
        key: ValueKey('image-gallery-$index'),
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: shape,
              child: bytes == null
                  ? ColoredBox(
                      color: scheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  : Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stackTrace) => ColoredBox(
                        color: scheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
            ),
            if (!readOnly)
              Positioned(
                top: 2,
                right: 2,
                child: Material(
                  color: scheme.surface.withValues(alpha: 0.85),
                  shape: const CircleBorder(),
                  child: InkWell(
                    key: ValueKey('image-gallery-remove-$index'),
                    customBorder: const CircleBorder(),
                    onTap: _busy ? null : () => _remove(index),
                    child: Tooltip(
                      message: l10n.removeImageTooltip,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, size: 16),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    Widget addTile(IconData icon, String label, ImageSource source) => Tooltip(
      message: label,
      child: InkWell(
        borderRadius: shape,
        onTap: _busy ? null : () => _pick(source, room),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: shape,
          ),
          alignment: Alignment.center,
          child: _busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: scheme.primary),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
        ),
      ),
    );

    return FormatFieldFrame(
      label: fieldLabel(widget.schema, widget.path, widget.isRequired),
      description: widget.schema.description,
      editorTheme: editorTheme,
      errorText:
          _pickError ??
          (invalid ? l10n.invalidImageData : null) ??
          localizeFirstValidationError(l10n, errors),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < images.length; i++) thumbnail(i),
          if (!readOnly && room > 0) ...[
            addTile(
              Icons.add_photo_alternate_outlined,
              l10n.choosePictureLabel,
              ImageSource.gallery,
            ),
            if (_cameraSupported)
              addTile(
                Icons.photo_camera_outlined,
                l10n.takePhotoLabel,
                ImageSource.camera,
              ),
          ],
        ],
      ),
    );
  }
}
