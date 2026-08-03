import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_json_editor/flutter_json_editor.dart';

Map<String, dynamic> _schema() => {
      'type': 'object',
      'properties': {
        'category': {
          'type': 'string',
          'title': 'What is affected?',
          'oneOf': [
            {'const': 'heat', 'title': 'Heating'},
            {'const': 'lift', 'title': 'Lift'},
          ],
        },
        'subcategory': {'type': 'string', 'title': 'What exactly is wrong?'},
        'floor': {'type': 'string', 'title': 'Floor', 'default': 'everywhere'},
        'note': {'type': 'string', 'title': 'Note'},
        'detail': {'type': 'string', 'title': 'Detail only for heating'},
      },
      'required': ['category', 'subcategory', 'floor'],
      'allOf': [
        {
          'if': {
            'properties': {
              'category': {'const': 'heat'}
            }
          },
          'then': {
            'required': ['detail']
          }
        }
      ],
    };

List<String> _keys(List<MissingRequiredField> fields) =>
    fields.map((f) => f.key).toList();

void main() {
  test('reports base required fields that are empty', () {
    final missing = findMissingRequired(_schema(), {});
    // floor has a default, so it never reports; detail only via the conditional.
    expect(_keys(missing), containsAll(['category', 'subcategory']));
    expect(_keys(missing), isNot(contains('floor')));
    expect(_keys(missing), isNot(contains('detail')));
  });

  test('carries the property title', () {
    final missing = findMissingRequired(_schema(), {});
    final category = missing.firstWhere((f) => f.key == 'category');
    expect(category.title, 'What is affected?');
  });

  test('filled fields drop out; blank strings still count as missing', () {
    final missing = findMissingRequired(_schema(), {
      'category': 'lift',
      'subcategory': '   ', // whitespace only -> still missing
    });
    expect(_keys(missing), ['subcategory']);
  });

  test('activates then.required when the if condition matches', () {
    final missing = findMissingRequired(_schema(), {
      'category': 'heat',
      'subcategory': 'x',
    });
    // category='heat' triggers the conditional requirement of `detail`.
    expect(_keys(missing), ['detail']);
  });

  test('does not activate then.required when the if does not match', () {
    final missing = findMissingRequired(_schema(), {
      'category': 'lift',
      'subcategory': 'x',
    });
    expect(missing, isEmpty);
  });

  test('returns nothing for a schema without properties', () {
    expect(findMissingRequired({'type': 'string'}, {}), isEmpty);
  });
}
