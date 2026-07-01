import 'package:acafe_customer/common/models/product_model.dart';
import 'package:acafe_customer/features/kiosk/domain/kiosk_menu_filter.dart';
import 'package:acafe_customer/features/search/providers/search_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSearchProvider implements SearchProvider {
  _FakeSearchProvider({
    this.selectedSortByIndex,
    this.selectedPriceIndex,
    this.priceFilterList = const [],
  });

  @override
  final int? selectedSortByIndex;
  @override
  final int? selectedPriceIndex;
  @override
  final List<List<int>> priceFilterList;

  @override
  List<String> get getSortByList =>
      const ['a_to_z', 'z_to_a', 'price_high_to_low', 'price_low_to_high'];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Product _product({required String name, required double price}) {
  return Product(name: name, price: price);
}

void main() {
  group('filterKioskProducts', () {
    test('sorts products A to Z', () {
      final result = filterKioskProducts(
        products: [
          _product(name: 'Zebra', price: 10),
          _product(name: 'Apple', price: 10),
        ],
        searchProvider: _FakeSearchProvider(selectedSortByIndex: 0),
      );

      expect(result.map((p) => p.name), ['Apple', 'Zebra']);
    });

    test('filters by price range', () {
      final result = filterKioskProducts(
        products: [
          _product(name: 'Cheap', price: 5),
          _product(name: 'Expensive', price: 50),
        ],
        searchProvider: _FakeSearchProvider(
          selectedPriceIndex: 0,
          priceFilterList: const [
            [0, 10],
          ],
        ),
      );

      expect(result.length, 1);
      expect(result.first.name, 'Cheap');
    });
  });
}
