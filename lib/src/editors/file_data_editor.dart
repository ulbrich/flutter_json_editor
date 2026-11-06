import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart' as fp;
import 'package:json_schema/json_schema.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/json_editor_l10n.dart';
import '../schema_field_editor.dart';
import '../schema_utils.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';
import 'format_support.dart';
import 'image_data_editor.dart';

/// A file chosen by the user, as handed to [FileDataEditor].
class PickedFileData {
  const PickedFileData({
    required this.name,
    required this.bytes,
    this.mimeType,
  });

  final String name;
  final Uint8List bytes;
  final String? mimeType;
}

/// Opens the platform's file chooser; [extensions] (without dots) limit the
/// choice when given. Returns the chosen files, empty when cancelled.
typedef FileDataPicker = Future<List<PickedFileData>> Function({
  required bool multiple,
  List<String>? extensions,
});

/// A file of any kind stored in the data itself as base64, activated by
/// `"x-format": "file-data"`:
///
/// ```json
/// {"type": "string", "title": "CV", "x-format": "file-data",
///  "contentMediaType": "application/pdf", "x-max-file-size": 2000000}
///
/// {"type": "array", "title": "Attachments", "x-format": "file-data",
///  "maxItems": 3, "x-accept": ["pdf", "docx", "png"],
///  "items": {"type": "object"}}
/// ```
///
/// The value depends on the schema:
/// - `string`: a data URI that carries the name,
///   `data:application/pdf;name=cv.pdf;base64,…`.
/// - `object`: `{"name": "cv.pdf", "type": "application/pdf",
///   "size": 48213, "data": "…base64…"}`.
/// - `array` of either: several files, up to `maxItems`.
///
/// `x-accept` (file extensions) or else `contentMediaType` (`image/*`
/// works) limit the choice; `x-max-file-size` caps each file in bytes
/// (default [FileDataEditor.defaultMaxFileSize]). Choosing uses the
/// `file_picker` plugin through [FileDataEditor.picker], which apps and
/// tests may replace. Other schemas render with the editor they would get
/// without the `x-format`.
class FileDataEditor extends SchemaFieldEditor {
  const FileDataEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
  });

  /// Largest file, in bytes, without `x-max-file-size`: 5 MiB.
  static const int defaultMaxFileSize = 5 * 1024 * 1024;

  /// How files are chosen; the `file_picker` plugin by default.
  static FileDataPicker picker = _pickWithPlugin;

  static Future<List<PickedFileData>> _pickWithPlugin({
    required bool multiple,
    List<String>? extensions,
  }) async {
    final type = extensions == null ? fp.FileType.any : fp.FileType.custom;
    final single = multiple
        ? null
        : await fp.FilePicker.pickFile(
            type: type,
            allowedExtensions: extensions,
          );
    final files = multiple
        ? await fp.FilePicker.pickFiles(
            type: type,
            allowedExtensions: extensions,
          )
        : [?single];
    return [
      for (final file in files)
        PickedFileData(
          name: file.name,
          bytes: await file.xFile.readAsBytes(),
          mimeType: file.xFile.mimeType,
        ),
    ];
  }

  static const Map<String, String> _types = {
    'pdf': 'application/pdf',
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'heic': 'image/heic',
    'svg': 'image/svg+xml',
    'txt': 'text/plain',
    'csv': 'text/csv',
    'md': 'text/markdown',
    'json': 'application/json',
    'xml': 'application/xml',
    'zip': 'application/zip',
    'doc': 'application/msword',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'odt': 'application/vnd.oasis.opendocument.text',
    'ods': 'application/vnd.oasis.opendocument.spreadsheet',
    'mp3': 'audio/mpeg',
    'm4a': 'audio/mp4',
    'wav': 'audio/wav',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
  };

  /// The MIME type for a file [name] by its extension; null when unknown.
  static String? mimeTypeForName(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0) return null;
    return _types[name.substring(dot + 1).toLowerCase()];
  }

  /// The extensions for a `contentMediaType` (`image/*` included); null
  /// when it names none this editor knows.
  static List<String>? extensionsForType(String? mediaType) {
    if (mediaType == null) return null;
    final type = mediaType.toLowerCase();
    final result = [
      for (final entry in _types.entries)
        if (type.endsWith('/*')
            ? entry.value.startsWith(type.substring(0, type.length - 1))
            : entry.value == type)
          entry.key,
    ];
    return result.isEmpty ? null : result;
  }

  /// A file value (data URI or object) as name, type and bytes; null when
  /// it is neither.
  static ({String name, String? type, Uint8List bytes})? read(dynamic value) {
    if (value is Map) {
      final bytes = ImageDataEditor.decode(value['data']?.toString());
      if (bytes == null) return null;
      return (
        name: value['name']?.toString() ?? '',
        type: value['type']?.toString(),
        bytes: bytes,
      );
    }
    if (value is String) {
      final bytes = ImageDataEditor.decode(value);
      if (bytes == null) return null;
      String? type;
      var name = '';
      if (value.startsWith('data:')) {
        final header = value.substring(5, value.indexOf(','));
        final parts = header.split(';');
        if (parts.first.contains('/')) type = parts.first;
        for (final part in parts.skip(1)) {
          if (part.startsWith('name=')) {
            name = Uri.decodeComponent(part.substring(5));
          }
        }
      }
      return (name: name, type: type, bytes: bytes);
    }
    return null;
  }

  /// [file] in the form [schema] stores: a data URI for strings, an object
  /// otherwise.
  static dynamic store(JsonSchema schema, PickedFileData file) {
    final type =
        file.mimeType ??
        mimeTypeForName(file.name) ??
        ImageDataEditor.mimeTypeOf(file.bytes) ??
        'application/octet-stream';
    final data = base64.encode(file.bytes);
    if (schemaTypeNames(schema).contains('string')) {
      return 'data:$type;name=${Uri.encodeComponent(file.name)};base64,$data';
    }
    return {
      'name': file.name,
      'type': type,
      'size': file.bytes.length,
      'data': data,
    };
  }

  /// A size in bytes as "12 KB" or "1.5 MB".
  static String formatSize(int bytes) {
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  @override
  State<FileDataEditor> createState() => _FileDataEditorState();
}

class _FileDataEditorState extends State<FileDataEditor> {
  bool _busy = false;
  String? _error;

  bool get _isList => schemaTypeNames(widget.schema).contains('array');

  /// The schema of one file: the items of a list, else the field's own.
  JsonSchema get _fileSchema => _isList && widget.schema.items != null
      ? SchemaUtils.resolveRef(widget.schema.items!)
      : widget.schema;

  Map<dynamic, dynamic> get _map =>
      widget.schema.schemaMap ?? const <String, dynamic>{};

  List<String>? get _extensions {
    final accept = _map['x-accept'];
    if (accept is List && accept.isNotEmpty) {
      return [for (final e in accept) '$e'.toLowerCase().replaceFirst('.', '')];
    }
    final type =
        _map['contentMediaType'] ?? _fileSchema.schemaMap?['contentMediaType'];
    return FileDataEditor.extensionsForType(type is String ? type : null);
  }

  int get _maxSize {
    final value = _map['x-max-file-size'];
    return value is num && value > 0
        ? value.toInt()
        : FileDataEditor.defaultMaxFileSize;
  }

  List<dynamic> get _files {
    final value = widget.value;
    if (_isList) return value is List ? List<dynamic>.from(value) : [];
    return value == null ? [] : [value];
  }

  Future<void> _pick() async {
    final l10n = JsonEditorL10n.of(context);
    final extensions = _extensions;
    final maxSize = _maxSize;
    final maxItems = widget.schema.maxItems;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final picked = await FileDataEditor.picker(
        multiple: _isList,
        extensions: extensions,
      );
      if (picked.isEmpty) return;
      final accepted = <dynamic>[];
      String? error;
      for (final file in picked) {
        final dot = file.name.lastIndexOf('.');
        final ext = dot < 0 ? '' : file.name.substring(dot + 1).toLowerCase();
        if (extensions != null && !extensions.contains(ext)) {
          error = l10n.fileTypeNotAllowed(extensions.join(', '));
        } else if (file.bytes.length > maxSize) {
          error = l10n.fileTooLarge(FileDataEditor.formatSize(maxSize));
        } else {
          accepted.add(FileDataEditor.store(_fileSchema, file));
        }
      }
      if (accepted.isNotEmpty) {
        if (_isList) {
          var files = [..._files, ...accepted];
          if (maxItems != null && files.length > maxItems) {
            files = files.sublist(0, maxItems);
          }
          widget.onChanged(files);
        } else {
          widget.onChanged(accepted.first);
        }
      }
      if (mounted) setState(() => _error = error);
    } catch (_) {
      if (mounted) setState(() => _error = l10n.filePickFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _remove(int index) {
    if (_isList) {
      final files = _files..removeAt(index);
      widget.onChanged(files.isEmpty && !widget.isRequired ? null : files);
    } else {
      widget.onChanged(null);
    }
  }

  IconData _icon(String? type) {
    if (type == null) return Icons.insert_drive_file_outlined;
    if (type == 'application/pdf') return Icons.picture_as_pdf_outlined;
    if (type.startsWith('image/')) return Icons.image_outlined;
    if (type.startsWith('audio/')) return Icons.audio_file_outlined;
    if (type.startsWith('video/')) return Icons.video_file_outlined;
    if (type.startsWith('text/') || type.contains('document')) {
      return Icons.description_outlined;
    }
    if (type.contains('sheet') || type.contains('excel')) {
      return Icons.table_chart_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final types = schemaTypeNames(_fileSchema);
    if (!types.contains('string') && !types.contains('object')) {
      return editorWithoutFormat(
        context,
        format: 'file-data',
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
    final files = _files;
    final maxItems = widget.schema.maxItems;
    final canAdd =
        !readOnly &&
        (_isList ? maxItems == null || files.length < maxItems : true);
    final hasInvalid = files.any((f) => FileDataEditor.read(f) == null);

    return FormatFieldFrame(
      label: fieldLabel(widget.schema, widget.path, widget.isRequired),
      description: widget.schema.description,
      editorTheme: editorTheme,
      errorText: _error ?? (hasInvalid ? l10n.invalidFileData : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < files.length; i++)
            Builder(
              builder: (context) {
                final file = FileDataEditor.read(files[i]);
                final name = file == null || file.name.isEmpty
                    ? l10n.unnamedFile
                    : file.name;
                final type = file?.type ?? FileDataEditor.mimeTypeForName(name);
                return Card(
                  key: ValueKey('file-data-$i'),
                  margin: const EdgeInsets.only(bottom: 6),
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Icon(_icon(type)),
                    title: Text(name, overflow: TextOverflow.ellipsis),
                    subtitle: file == null
                        ? null
                        : Text(FileDataEditor.formatSize(file.bytes.length)),
                    trailing: readOnly
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: l10n.removeFileTooltip,
                            onPressed: _busy ? null : () => _remove(i),
                          ),
                  ),
                );
              },
            ),
          if (canAdd)
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: Text(
                    files.isNotEmpty && !_isList
                        ? l10n.replaceFileLabel
                        : l10n.chooseFileLabel,
                  ),
                  onPressed: _busy ? null : _pick,
                ),
                if (_busy)
                  const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          if (!readOnly)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                [
                  if (_extensions != null)
                    _extensions!.join(', ').toUpperCase(),
                  l10n.maxFileSizeHint(FileDataEditor.formatSize(_maxSize)),
                ].join(' · '),
                style: editorTheme.helperStyle ?? theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
