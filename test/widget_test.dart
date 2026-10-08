import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retail_inventory_ai/main.dart';
import 'package:retail_inventory_ai/workspace/workspace_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late WorkspaceStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = WorkspaceStore(await SharedPreferences.getInstance())..restore();
  });
  test('Workspace starts empty and survives restart', () async {
    expect(store.items, isEmpty);
    expect(store.units, 0);
    await store.configure('My shop', 'https://example.com/');
    await store.saveItem(
      StockItem(
        id: 'one',
        values: {
          'product': 'Rice',
          'store': 'Branch A',
          'inventory': 12,
          'reorder_point': 15,
          'cost_price': 20,
        },
      ),
    );
    final restored = WorkspaceStore(await SharedPreferences.getInstance())
      ..restore();
    expect(restored.business, 'My shop');
    expect(restored.endpoint, 'https://example.com');
    expect(restored.units, 12);
    expect(restored.lowStock, 1);
    expect(restored.stockValue, 240);
    await restored.deleteItem('one');
    final empty = WorkspaceStore(await SharedPreferences.getInstance())
      ..restore();
    expect(empty.items, isEmpty);
  });
  test('Editing inventory invalidates old forecast', () async {
    await store.saveItem(
      StockItem(
        id: 'one',
        values: {
          'product': 'Rice',
          'store': 'A',
          'inventory': 10,
          'reorder_point': 5,
          'cost_price': 2,
        },
        forecast: {'expected_demand': 20},
      ),
    );
    await store.saveItem(
      StockItem(
        id: 'one',
        values: {
          'product': 'Rice',
          'store': 'A',
          'inventory': 30,
          'reorder_point': 5,
          'cost_price': 2,
        },
      ),
    );
    expect(store.items.single.forecast, isNull);
    expect(store.units, 30);
  });
  test('Forecast sends saved values and persists only real response', () async {
    final client = MockClient((request) async {
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      expect(payload['inventory'], 17);
      expect(payload['cost_price'], 12);
      expect(payload['previous_week_sales'], 23);
      expect(payload['day_of_week'], 'Tuesday');
      expect(payload['promotion'], 'High');
      return http.Response(
        jsonEncode({
          'expected_demand': 25,
          'restock_quantity': 13,
          'recommended_inventory': 30,
        }),
        200,
      );
    });
    final tested = WorkspaceStore(
      await SharedPreferences.getInstance(),
      client: client,
    );
    await tested.configure('Shop', 'https://example.com');
    final item = StockItem(
      id: 'forecast',
      values: {
        'product': 'Rice',
        'store': 'Branch B',
        'store_type': 'Urban',
        'category': 'Groceries',
        'inventory': 17,
        'reorder_point': 10,
        'price': 20,
        'cost_price': 12,
        'competitor_price': 21,
        'discount': 5,
        'previous_week_sales': 23,
        'previous_month_sales': 90,
        'temperature': 27,
        'rainfall_mm': 2,
        'season': 'Post-Monsoon',
        'promotion': 'High',
        'holiday': 'No',
        'date': '2026-10-06',
      },
    );
    await tested.saveItem(item);
    await tested.forecast(item);
    expect(item.forecast?['expected_demand'], 25);
    final restored = WorkspaceStore(await SharedPreferences.getInstance())
      ..restore();
    expect(restored.items.single.forecast?['restock_quantity'], 13);
    expect(tested.busyId, isNull);
    tested.dispose();
  });
  testWidgets(
    'First launch offers business setup instead of fake authentication',
    (tester) async {
      await tester.pumpWidget(RetailInventoryApp(store: store));
      expect(find.text('Set up your business'), findsOneWidget);
      expect(find.text('Create workspace'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    },
  );
}
