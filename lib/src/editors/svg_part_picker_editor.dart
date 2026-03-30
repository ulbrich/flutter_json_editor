import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xml/xml.dart';

import '../schema_field_editor.dart';
import '../theme/editor_theme.dart';
import '../theme/editor_theme_defaults.dart';

/// A region extracted from the SVG with its id and absolute bounding box.
class _SvgRegion {
  final String id;
  final String? label;
  final Rect bounds;

  const _SvgRegion({required this.id, this.label, required this.bounds});
}

/// A parsed CSS rule with its selector and property map.
class _CssRule {
  final String selector;
  final Map<String, String> properties;

  const _CssRule({required this.selector, required this.properties});
}

/// An interactive SVG-based part picker editor.
///
/// Renders an SVG asset and allows the user to toggle selection of regions
/// (elements with `class="region"` and an `id` attribute). The value is
/// stored as either a `List<String>` of selected IDs or a comma-separated
/// `String`, matching the format of the incoming value.
///
/// Schema properties:
/// - `x-format`: `"svg-part-picker"` (required to activate this editor)
/// - `x-svg-asset`: asset path to the SVG file (e.g. `"assets/images/body-parts.svg"`)
///
/// IDs present in the incoming data but not found in the SVG are preserved
/// in the output so that editing with one SVG does not destroy data that
/// belongs to a different aspect/SVG.
class SvgPartPickerEditor extends SchemaFieldEditor {
  const SvgPartPickerEditor({
    super.key,
    required super.schema,
    required super.path,
    required super.value,
    required super.onChanged,
    required super.isRequired,
    super.isNullable,
  });

  @override
  State<SvgPartPickerEditor> createState() => _SvgPartPickerEditorState();
}

class _SvgPartPickerEditorState extends State<SvgPartPickerEditor> {
  String? _rawSvg;
  bool _loading = true;
  String? _error;

  /// All selected IDs – includes IDs not present in the SVG.
  final Set<String> _selectedIds = {};

  /// IDs from the input that do not appear as region ids in the SVG.
  final Set<String> _unknownIds = {};

  /// Parsed clickable regions with absolute bounds in SVG coordinate space.
  final List<_SvgRegion> _regions = [];

  /// The viewBox size of the SVG (used for hit-testing coordinate conversion).
  Size _viewBoxSize = const Size(300, 150);

  /// Whether the incoming value was a List (true) or a comma-separated String
  /// (false).  Determines the output format.
  bool _inputWasArray = false;

  /// CSS rules parsed from the SVG's <style> block.
  List<_CssRule> _cssRules = const [];

  /// CSS properties that have no effect in flutter_svg and should not be
  /// inlined as presentation attributes.
  static const _ignoredCssProperties = {
    'cursor',
    'transition',
  };

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _parseInputValue(widget.value);
    _loadSvg();
  }

  @override
  void didUpdateWidget(SvgPartPickerEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reload SVG when asset path changes.
    final oldAsset = oldWidget.schema.schemaMap?['x-svg-asset'];
    final newAsset = widget.schema.schemaMap?['x-svg-asset'];
    if (oldAsset != newAsset) {
      _loadSvg();
    }

    // Re-sync selection when the value is changed externally.
    if (widget.value != oldWidget.value) {
      _parseInputValue(widget.value);
      _refreshUnknownIds();
      setState(() {});
    }
  }

  // ---------------------------------------------------------------------------
  // Value parsing
  // ---------------------------------------------------------------------------

  void _parseInputValue(dynamic value) {
    _selectedIds.clear();
    if (value is List) {
      _inputWasArray = true;
      _selectedIds.addAll(
        value
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty),
      );
    } else if (value is String && value.isNotEmpty) {
      _inputWasArray = false;
      _selectedIds.addAll(
        value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty),
      );
    } else {
      // No value yet – derive the output format from the schema type.
      final schemaType = widget.schema.typeList;
      _inputWasArray =
          schemaType != null && schemaType.any((t) => t.toString() == 'array');
    }
  }

  // ---------------------------------------------------------------------------
  // SVG loading & region extraction
  // ---------------------------------------------------------------------------

  Future<void> _loadSvg() async {
    final assetPath = widget.schema.schemaMap?['x-svg-asset'] as String?;
    if (assetPath == null || assetPath.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'No SVG asset path specified (x-svg-asset).';
        });
      }
      return;
    }

    try {
      final svgString = await rootBundle.loadString(assetPath);
      _parseRegions(svgString);
      _refreshUnknownIds();
      if (mounted) {
        setState(() {
          _rawSvg = svgString;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load SVG: $e';
        });
      }
    }
  }

  void _parseRegions(String svgString) {
    _regions.clear();
    final document = XmlDocument.parse(svgString);
    final root = document.rootElement;

    // Parse viewBox.
    final vb = root.getAttribute('viewBox');
    if (vb != null) {
      final parts =
          vb.split(RegExp(r'[\s,]+')).map(double.tryParse).toList();
      if (parts.length >= 4 && parts[2] != null && parts[3] != null) {
        _viewBoxSize = Size(parts[2]!, parts[3]!);
      }
    }

    // Parse CSS rules from <style> blocks so we can inline them later
    // (flutter_svg does not support <style> / CSS selectors).
    _cssRules = _extractCssRules(root);

    _visitElement(root, Offset.zero);
  }

  void _visitElement(XmlElement element, Offset parentOffset) {
    var offset = parentOffset;

    // Accumulate translate() transforms.
    final transform = element.getAttribute('transform');
    if (transform != null) {
      final m = RegExp(
        r'translate\(\s*([-\d.]+)\s*[,\s]\s*([-\d.]+)\s*\)',
      ).firstMatch(transform);
      if (m != null) {
        offset = Offset(
          parentOffset.dx + double.parse(m.group(1)!),
          parentOffset.dy + double.parse(m.group(2)!),
        );
      }
    }

    final id = element.getAttribute('id');
    final dataState = element.getAttribute('data-state');
    // Any element with both an id and a data-state attribute is a selectable
    // region – regardless of the CSS class name used for styling.
    if (id != null && dataState != null) {
      final bounds = _boundsOf(element, offset);
      if (bounds != null) {
        final label = element.getAttribute('data-region');
        _regions.add(_SvgRegion(id: id, label: label, bounds: bounds));
      }
    }

    for (final child in element.children.whereType<XmlElement>()) {
      _visitElement(child, offset);
    }
  }

  Rect? _boundsOf(XmlElement el, Offset offset) {
    double attr(String name) =>
        double.tryParse(el.getAttribute(name) ?? '') ?? 0;

    switch (el.name.local) {
      case 'rect':
        return Rect.fromLTWH(
          attr('x') + offset.dx,
          attr('y') + offset.dy,
          attr('width'),
          attr('height'),
        );
      case 'ellipse':
        return Rect.fromCenter(
          center: Offset(attr('cx') + offset.dx, attr('cy') + offset.dy),
          width: attr('rx') * 2,
          height: attr('ry') * 2,
        );
      case 'circle':
        final r = attr('r');
        return Rect.fromCenter(
          center: Offset(attr('cx') + offset.dx, attr('cy') + offset.dy),
          width: r * 2,
          height: r * 2,
        );
      default:
        return null;
    }
  }

  void _refreshUnknownIds() {
    final knownIds = _regions.map((r) => r.id).toSet();
    _unknownIds
      ..clear()
      ..addAll(_selectedIds.where((id) => !knownIds.contains(id)));
  }

  // ---------------------------------------------------------------------------
  // Generic CSS → inline attribute conversion
  // ---------------------------------------------------------------------------

  /// Extract and parse all CSS rules from `<style>` elements in the SVG.
  static List<_CssRule> _extractCssRules(XmlElement root) {
    final rules = <_CssRule>[];
    for (final style in root.descendants.whereType<XmlElement>().where(
      (e) => e.name.local == 'style',
    )) {
      final css = style.innerText;
      rules.addAll(_parseCssText(css));
    }
    return rules;
  }

  /// Minimal CSS parser – handles class selectors, attribute selectors, and
  /// skips pseudo-class selectors like `:hover`.
  static List<_CssRule> _parseCssText(String css) {
    final rules = <_CssRule>[];
    final ruleRe = RegExp(r'([^{}]+)\{([^}]*)\}');
    for (final m in ruleRe.allMatches(css)) {
      final rawSelector = m.group(1)!.trim();
      final declarations = m.group(2)!.trim();

      // Skip rules with pseudo-classes (e.g. :hover) – they have no
      // equivalent in flutter_svg.
      if (rawSelector.contains(':')) continue;

      final props = <String, String>{};
      for (final decl in declarations.split(';')) {
        final colon = decl.indexOf(':');
        if (colon < 0) continue;
        final prop = decl.substring(0, colon).trim();
        if (_ignoredCssProperties.contains(prop)) continue;
        var value = decl.substring(colon + 1).trim();
        // Strip units that flutter_svg handles implicitly.
        value = value.replaceAll('px', '');
        props[prop] = value;
      }

      if (props.isNotEmpty) {
        rules.add(_CssRule(selector: rawSelector, properties: props));
      }
    }
    return rules;
  }

  /// Build the modified SVG string with `<style>` removed, `data-state`
  /// toggled, and all matching CSS rules inlined as presentation attributes.
  String _buildStyledSvg() {
    if (_rawSvg == null) return '';
    final doc = XmlDocument.parse(_rawSvg!);
    final root = doc.rootElement;

    // 1. Remove <style> elements (flutter_svg warns about them).
    root.descendants
        .whereType<XmlElement>()
        .where((e) => e.name.local == 'style')
        .toList()
        .forEach((e) => e.parent?.children.remove(e));

    // 2. Set data-state on region elements based on current selection,
    //    then inline CSS rules on every element.
    _inlineStyles(root, _cssRules, inheritedProps: const {});

    return doc.toXmlString();
  }

  /// Recursively walk the SVG tree, update `data-state` for region elements,
  /// then apply matching CSS rules as presentation attributes.
  ///
  /// [inheritedProps] carries CSS properties from a parent `<g>` that should
  /// be set on children that don't override them (mimics CSS inheritance).
  void _inlineStyles(
    XmlElement element,
    List<_CssRule> rules, {
    required Map<String, String> inheritedProps,
  }) {
    // Update data-state for selectable elements before matching rules, so
    // that attribute selectors like [data-state="selected"] resolve correctly.
    // Any element that carries a data-state attribute is considered selectable.
    final id = element.getAttribute('id');
    if (id != null && element.getAttribute('data-state') != null) {
      element.setAttribute(
        'data-state',
        _selectedIds.contains(id) ? 'selected' : 'default',
      );
    }

    // Collect all matching CSS properties (in rule order – later wins).
    final matched = <String, String>{};
    for (final rule in rules) {
      if (_selectorMatches(rule.selector, element)) {
        matched.addAll(rule.properties);
      }
    }

    // Merge inherited properties (only fill in what isn't already set).
    final effective = {...inheritedProps, ...matched};

    // Apply to the element. For leaf elements like <text>, <rect>, etc.
    // set them directly. For <g> elements, only set them if the element
    // itself matched at least one rule (otherwise just pass down).
    if (matched.isNotEmpty) {
      for (final e in matched.entries) {
        // Preserve element-level attributes that were set explicitly in
        // the SVG source (higher specificity than class rules), unless the
        // attribute was already set by an earlier CSS pass on this call.
        //
        // Exception: we always overwrite for matched rules because the
        // SVG source attributes are defaults and the CSS class rules are
        // meant to override them.
        element.setAttribute(e.key, e.value);
      }
    }

    // For elements that inherit from a parent <g> but didn't match any
    // rule themselves, apply inherited properties that are missing.
    if (matched.isEmpty && inheritedProps.isNotEmpty) {
      for (final e in inheritedProps.entries) {
        if (element.getAttribute(e.key) == null) {
          element.setAttribute(e.key, e.value);
        }
      }
    }

    // Recurse into children, passing along inheritable properties.
    for (final child in element.children.whereType<XmlElement>()) {
      _inlineStyles(child, rules, inheritedProps: effective);
    }
  }

  /// Check whether [selector] matches [element].
  ///
  /// Supports:
  /// - `.className`
  /// - `.className[attr="value"]`
  /// - Compound selectors are not supported (no descendant / child combinators).
  static bool _selectorMatches(String selector, XmlElement element) {
    final classRe = RegExp(r'^\.([a-zA-Z_][\w-]*)');
    final classMatch = classRe.firstMatch(selector);
    if (classMatch == null) return false;

    final wantClass = classMatch.group(1)!;
    final elementClass = element.getAttribute('class');
    if (elementClass != wantClass) return false;

    // Check all attribute selectors, e.g. [data-state="selected"].
    final attrRe = RegExp(r'\[([\w-]+)="([^"]*)"\]');
    for (final am in attrRe.allMatches(selector)) {
      if (element.getAttribute(am.group(1)!) != am.group(2)!) {
        return false;
      }
    }

    return true;
  }

  // ---------------------------------------------------------------------------
  // Interaction
  // ---------------------------------------------------------------------------

  void _handleTap(Offset localPosition, Size widgetSize) {
    // Convert from widget coordinates to SVG viewBox coordinates.
    final scaleX = widgetSize.width / _viewBoxSize.width;
    final scaleY = widgetSize.height / _viewBoxSize.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final renderedW = _viewBoxSize.width * scale;
    final renderedH = _viewBoxSize.height * scale;
    final offsetX = (widgetSize.width - renderedW) / 2;
    final offsetY = (widgetSize.height - renderedH) / 2;

    final svgX = (localPosition.dx - offsetX) / scale;
    final svgY = (localPosition.dy - offsetY) / scale;

    if (svgX < 0 ||
        svgY < 0 ||
        svgX > _viewBoxSize.width ||
        svgY > _viewBoxSize.height) {
      return;
    }

    // Find the tapped region (last match wins so smaller overlapping regions
    // that are painted on top are preferred).
    _SvgRegion? hit;
    for (final region in _regions) {
      if (region.bounds.contains(Offset(svgX, svgY))) {
        hit = region;
      }
    }

    if (hit == null) return;

    setState(() {
      if (_selectedIds.contains(hit!.id)) {
        _selectedIds.remove(hit.id);
      } else {
        _selectedIds.add(hit.id);
      }
      _refreshUnknownIds();
    });
    _emitValue();
  }

  void _emitValue() {
    final ids = _selectedIds.toList();
    if (_inputWasArray) {
      widget.onChanged(ids);
    } else {
      widget.onChanged(ids.join(','));
    }
  }

  // ---------------------------------------------------------------------------
  // Label
  // ---------------------------------------------------------------------------

  String _buildLabel() {
    final base = widget.schema.title ?? widget.path.split('.').last;
    return widget.isRequired ? '$base *' : base;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final editorTheme = Theme.of(context).extension<JsonEditorTheme>() ??
        EditorThemeDefaults.fromContext(context);

    if (_loading) {
      return Padding(
        padding: editorTheme.fieldPadding,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _rawSvg == null) {
      return Padding(
        padding: editorTheme.fieldPadding,
        child: Text(
          _error ?? 'SVG not available.',
          style: editorTheme.errorStyle ??
              TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    final selectedKnown =
        _selectedIds.where((id) => !_unknownIds.contains(id)).toList();
    final chipLabels = selectedKnown.map((id) {
      final region = _regions.where((r) => r.id == id).firstOrNull;
      return region?.label ?? id;
    }).toList();

    return Padding(
      padding: editorTheme.fieldPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            children: [
              Expanded(
                child: Text(
                  _buildLabel(),
                  style: editorTheme.labelStyle ??
                      Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (widget.isNullable && widget.value != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: 'Clear to null',
                  onPressed: () => widget.onChanged(null),
                ),
            ],
          ),

          // Description
          if (widget.schema.description != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                widget.schema.description!,
                style: editorTheme.helperStyle ??
                    Theme.of(context).textTheme.bodySmall,
              ),
            ),

          const SizedBox(height: 8),

          // Interactive SVG
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height =
                  width * (_viewBoxSize.height / _viewBoxSize.width);

              return GestureDetector(
                onTapUp: (details) =>
                    _handleTap(details.localPosition, Size(width, height)),
                child: SizedBox(
                  width: width,
                  height: height,
                  child: SvgPicture.string(
                    _buildStyledSvg(),
                    fit: BoxFit.contain,
                    width: width,
                    height: height,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // Selection chips
          if (chipLabels.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final label in chipLabels)
                  Chip(
                    label: Text(label, style: const TextStyle(fontSize: 12)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),

          // Hint about preserved unknown IDs
          if (_unknownIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+ ${_unknownIds.length} ID(s) not in this SVG (preserved)',
                style: editorTheme.helperStyle ??
                    Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
              ),
            ),
        ],
      ),
    );
  }
}
