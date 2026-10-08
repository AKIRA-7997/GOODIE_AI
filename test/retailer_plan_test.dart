import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:retail_inventory_ai/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retail_inventory_ai/workspace/workspace_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late WorkspaceStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = WorkspaceStore(await SharedPreferences.getInstance());
  });
  tearDown(() => store.dispose());
  test('Samples persist, never duplicate and removal preserves real products',
      () async {
    await store.configure('Actual business', '');
    await store
        .saveItem(StockItem(id: 'real', values: {'product': 'Real product'}));
    await store.addSamples();
    await store.addSamples();
    expect(store.items.length, 4);
    expect(store.business, 'Actual business');
    final restored = WorkspaceStore(await SharedPreferences.getInstance())
      ..restore();
    expect(restored.items.where((i) => i.values['sample'] == true).length, 3);
    restored.dispose();
    await store.removeSamples();
    expect(store.items.single.id, 'real');
  });
  test('Sample order uses actual sample sales and explicit buffer', () async {
    await store.addSamples();
    final rice = store.items.first;
    await store.planOrder(rice);
    expect(rice.forecast!['expected_demand'], 28);
    expect(rice.forecast!['recommended_inventory'], 34);
    expect(rice.forecast!['restock_quantity'], 22);
    expect(rice.forecast!['horizon_days'], 7);
    await store.planOrder(store.items.last);
    expect(store.items.last.forecast!['restock_quantity'], 0);
  });
  test('Unknown sales are not silently treated as zero', () async {
    final item = StockItem(id: 'unknown', values: {'inventory': 4});
    await expectLater(store.planOrder(item), throwsStateError);
    expect(item.forecast, isNull);
  });
  test('Stock movements persist, preserve history and invalidate plans',
      () async {
    await store.addSamples();
    final id = store.items.first.id;
    await store.planOrder(store.items.first);
    await store.changeStock(id, 5, delivery: false);
    expect(store.items.first.stock, 7);
    expect(store.items.first.forecast, isNull);
    expect(store.items.first.values['previous_week_sales'], 28);
    await store.changeStock(id, 10, delivery: true);
    expect(store.items.first.stock, 17);
    final restored = WorkspaceStore(await SharedPreferences.getInstance())
      ..restore();
    expect(restored.items.first.stock, 17);
    expect((restored.items.first.values['stock_activity'] as List).length, 2);
    restored.dispose();
  });
  test('Invalid sales never create negative stock or activity', () async {
    await store.addSamples();
    final id = store.items.first.id;
    for (final amount in [0, -1, 13, 1000001]) {
      await expectLater(
          store.changeStock(id, amount, delivery: false), throwsStateError);
    }
    expect(store.items.first.stock, 12);
    expect(store.items.first.values['stock_activity'], isNull);
  });
  for (final width in [390.0, 1200.0]) {
    testWidgets('Retail sample workflow fits $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await store.addSamples();
      await tester.pumpWidget(RetailInventoryApp(store: store));
      await tester.pumpAndSettle();
      expect(find.text('Sample data included'), findsOneWidget);
      await tester.tap(find.text('Stock plan'));
      await tester.pumpAndSettle();
      expect(find.text('What should I order?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
