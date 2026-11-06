import 'package:flutter_json_editor/flutter_json_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  dynamic run(dynamic rule, [dynamic data]) => JsonLogic.apply(rule, data);

  group('JsonLogic', () {
    test('literals pass through', () {
      expect(run(1), 1);
      expect(run('a'), 'a');
      expect(run([1, 2]), [1, 2]);
    });

    test('var reads dotted paths, array indices and defaults', () {
      final data = {
        'a': {'b': 3},
        'list': [10, 20],
      };
      expect(run({'var': 'a.b'}, data), 3);
      expect(run({'var': 'list.1'}, data), 20);
      expect(run({'var': ['x', 7]}, data), 7);
      expect(run({'var': ''}, data), data);
    });

    test('arithmetic', () {
      expect(run({'+': [1, 2, 3]}), 6);
      expect(run({'-': [5, 2]}), 3);
      expect(run({'-': [5]}), -5);
      expect(run({'*': [2, 2.5]}), 5);
      expect(run({'/': [1, 3]}), closeTo(0.3333, 0.001));
      expect(run({'%': [7, 3]}), 1);
      expect(run({'+': ['2', 3]}), 5);
      expect(run({'*': [0.1, 3]}), 0.3);
      expect(run({'round': [2.345, 2]}), 2.35);
      expect(run({'max': [1, 5, 3]}), 5);
      expect(run({'min': [1, 5, 3]}), 1);
    });

    test('comparison and logic', () {
      expect(run({'==': [1, '1']}), isTrue);
      expect(run({'===': [1, '1']}), isFalse);
      expect(run({'<': [1, 2, 3]}), isTrue);
      expect(run({'<=': [1, 1, 0]}), isFalse);
      expect(run({'!': [0]}), isTrue);
      expect(run({'!!': ['x']}), isTrue);
      expect(run({'and': [1, 0, 2]}), 0);
      expect(run({'or': [0, '', 'x']}), 'x');
      expect(run({'if': [false, 'a', true, 'b', 'c']}), 'b');
      expect(run({'?:': [true, 1, 2]}), 1);
    });

    test('arrays and strings', () {
      final data = {
        'items': [
          {'qty': 2, 'price': 3},
          {'qty': 1, 'price': 4},
        ],
      };
      expect(
        run({
          'reduce': [
            {'var': 'items'},
            {
              '+': [
                {'var': 'accumulator'},
                {
                  '*': [
                    {'var': 'current.qty'},
                    {'var': 'current.price'},
                  ],
                },
              ],
            },
            0,
          ],
        }, data),
        10,
      );
      expect(
        run({
          'map': [
            [1, 2],
            {
              '*': [
                {'var': ''},
                2,
              ],
            },
          ],
        }),
        [2, 4],
      );
      expect(
        run({
          'filter': [
            [1, 2, 3],
            {
              '>': [
                {'var': ''},
                1,
              ],
            },
          ],
        }),
        [2, 3],
      );
      expect(run({'in': ['b', 'abc']}), isTrue);
      expect(run({'in': [2, [1, 2]]}), isTrue);
      expect(run({'cat': ['a', 1, 'b']}), 'a1b');
      expect(run({'substr': ['hello', 1, 3]}), 'ell');
      expect(run({'merge': [1, [2, 3]]}), [1, 2, 3]);
      expect(run({'missing': ['a', 'b']}, {'a': 1}), ['b']);
    });

    test('unknown operators throw', () {
      expect(() => run({'nope': [1]}), throwsA(isA<JsonLogicException>()));
    });

    test('variables lists every var a rule reads', () {
      expect(
        JsonLogic.variables({
          '+': [
            {'var': 'a'},
            {
              '*': [
                {'var': 'b.c'},
                2,
              ],
            },
          ],
        }),
        containsAll(['a', 'b.c']),
      );
    });
  });

  group('FormCalculator', () {
    final schema = SchemaUtils.createSchema({
      'type': 'object',
      'properties': {
        'qty': {'type': 'integer'},
        'price': {'type': 'number'},
        'net': {
          'type': 'number',
          'x-calc': {
            '*': [
              {'var': 'qty'},
              {'var': 'price'},
            ],
          },
        },
        'gross': {
          'type': 'number',
          'x-calc': {
            'round': [
              {
                '*': [
                  {'var': 'net'},
                  1.19,
                ],
              },
              2,
            ],
          },
        },
        'label': {
          'type': 'string',
          'x-calc': {
            'cat': [
              {'var': 'qty'},
              ' pcs',
            ],
          },
        },
      },
    });

    test('fills calculated fields, also from other calculations', () {
      final result = FormCalculator.apply(schema, {'qty': 3, 'price': 2.5});
      expect(result.data['net'], 7.5);
      expect(result.data['gross'], 8.93);
      expect(result.data['label'], '3 pcs');
      expect(result.cyclic, isEmpty);
    });

    test('does not change the input', () {
      final input = {'qty': 1, 'price': 1};
      FormCalculator.apply(schema, input);
      expect(input.containsKey('net'), isFalse);
    });

    test('marks cycles', () {
      final cyclic = SchemaUtils.createSchema({
        'type': 'object',
        'properties': {
          'a': {
            'type': 'integer',
            'x-calc': {
              '+': [
                {
                  'var': ['b', 0],
                },
                1,
              ],
            },
          },
          'b': {
            'type': 'integer',
            'x-calc': {
              '+': [
                {
                  'var': ['a', 0],
                },
                1,
              ],
            },
          },
        },
      });
      final result = FormCalculator.apply(cyclic, {});
      expect(result.cyclic, isNotEmpty);
    });

    test('hasCalculations', () {
      expect(FormCalculator.hasCalculations(schema), isTrue);
      expect(
        FormCalculator.hasCalculations(
          SchemaUtils.createSchema({
            'type': 'object',
            'properties': {
              'a': {'type': 'string'},
            },
          }),
        ),
        isFalse,
      );
    });
  });

  group('pipeText', () {
    test('replaces root and local paths', () {
      expect(
        pipeText('Hi {{name}}, {{.n}}!', {'name': 'Ada'}, {'n': 2}),
        'Hi Ada, 2!',
      );
    });

    test('shows a placeholder for missing answers', () {
      expect(pipeText('Hi {{name}}', {}, null), 'Hi …');
    });
  });

  group('InputMask', () {
    const iban = InputMask('AA00 0000 0000');

    test('lays out typed text and skips what does not fit', () {
      expect(iban.apply('de1212345678'), 'de12 1234 5678');
      expect(iban.apply('DE1'), 'DE1');
      expect(iban.apply('DE12'), 'DE12');
      expect(iban.apply('DE123'), 'DE12 3');
      expect(iban.apply('1DE'), 'DE');
    });

    test('raw, complete and hint', () {
      expect(iban.raw('DE12 1234 5678'), 'DE1212345678');
      expect(iban.isComplete('DE12 1234 5678'), isTrue);
      expect(iban.isComplete('DE12 1234'), isFalse);
      expect(iban.hint, '____ ____ ____');
    });

    test('leading literals are written before typed digits', () {
      const phone = InputMask('(000) 000-0000');
      expect(phone.apply('5551234567'), '(555) 123-4567');
      expect(phone.raw('(555) 123-4567'), '5551234567');
    });
  });
}
