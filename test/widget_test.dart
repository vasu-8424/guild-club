import 'package:flutter_test/flutter_test.dart';
import 'package:toyverse/repositories/mock_toy_data.dart';

void main() {
  test('ToyVerse mock data test', () {
    expect(MockToyData.products.isNotEmpty, isTrue);
    expect(MockToyData.categories.length, equals(6));
    expect(MockToyData.currentUser.rewardCoins, equals(480));
  });
}
