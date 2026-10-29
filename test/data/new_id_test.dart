import 'package:flutter_test/flutter_test.dart';
import 'package:kalkulatorserbaguna/data/models.dart';

// Also run with `flutter test --platform chrome test/data/new_id_test.dart`:
// on the web `1 << 32` is 0, which once made every newId() call throw.
void main() {
  test('newId works and is unique', () {
    final ids = {for (var i = 0; i < 2000; i++) newId()};
    expect(ids.length, 2000);
    expect(ids.every((id) => id.length >= 8), isTrue);
  });

  test('models that generate ids can be constructed', () {
    expect(ShoppingList(name: 'Belanja').id, isNotEmpty);
    expect(
        HistoryEntry(
                type: HistoryType.calculator,
                title: '1+1',
                result: '2',
                inputData: const {})
            .id,
        isNotEmpty);
  });
}
