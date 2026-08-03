import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_json_editor/flutter_json_editor.dart';

Map<String, dynamic> _schema() => {
      'properties': {
        'category': {
          'oneOf': [
            {'const': 'heat', 'title': 'Heating & water'},
            {'const': 'lift', 'title': 'Elevator'},
          ],
        },
        'note': {'type': 'string'},
        'acuteRisk': {'type': 'boolean'},
      },
    };

void main() {
  test('replaces coded values with their oneOf titles', () {
    final out = labelledData(_schema(), {
      'category': 'heat',
      'note': 'free text',
      'acuteRisk': true,
    });
    expect(out['category'], 'Heating & water');
    expect(out['note'], 'free text'); // free text unchanged
    expect(out['acuteRisk'], true); // boolean unchanged
  });

  test('leaves unmatched codes and unknown properties unchanged', () {
    final out = labelledData(_schema(), {'category': 'unknown', 'extra': 'x'});
    expect(out['category'], 'unknown');
    expect(out['extra'], 'x');
  });

  test('handles a schema without properties', () {
    expect(labelledData({'type': 'string'}, {'a': 1}), {'a': 1});
  });
}
