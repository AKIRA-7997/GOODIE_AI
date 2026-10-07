import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StockItem {
  StockItem({required this.id, required this.values, this.forecast});
  final String id;
  final Map<String, dynamic> values;
  Map<String, dynamic>? forecast;
  String get name => values['product'] as String;
  String get branch => values['store'] as String;
  int get stock => (values['inventory'] as num).toInt();
  int get reorder => (values['reorder_point'] as num).toInt();
  Map<String, dynamic> toJson() => {
        'id': id,
        'values': values,
        'forecast': forecast,
      };
  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem(
        id: json['id'] as String,
        values: Map<String, dynamic>.from(json['values'] as Map),
        forecast: json['forecast'] == null
            ? null
            : Map<String, dynamic>.from(json['forecast'] as Map),
      );
}

class WorkspaceStore extends ChangeNotifier {
  WorkspaceStore(this.preferences, {http.Client? client})
      : client = client ?? http.Client();
  final http.Client client;

  @override
  void dispose() {
    client.close();
    super.dispose();
  }

  final SharedPreferences preferences;
  static const storageKey = 'goodie.workspace.v1';
  String business = '';
  String endpoint = const String.fromEnvironment('GOODIE_API_URL');
  final List<StockItem> _items = [];
  List<StockItem> get items => List.unmodifiable(_items);
  String? busyId;
  String? loadError;
  bool get ready => business.isNotEmpty;
  int get units => _items.fold(0, (sum, item) => sum + item.stock);
  int get lowStock => _items.where((item) => item.stock <= item.reorder).length;
  Set<String> get branches => _items.map((item) => item.branch).toSet();
  double get stockValue => _items.fold(
        0,
        (sum, item) => sum + item.stock * (item.values['cost_price'] as num),
      );

  void restore() {
    try {
      final raw = preferences.getString(storageKey);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final restored = (json['items'] as List)
          .map(
            (item) =>
                StockItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      business = json['business'] as String;
      endpoint = json['endpoint'] as String;
      _items.addAll(restored);
    } catch (_) {
      loadError = 'Your saved workspace could not be opened.';
    }
  }

  Future<void> _persist() async {
    final saved = await preferences.setString(
      storageKey,
      jsonEncode({
        'business': business,
        'endpoint': endpoint,
        'items': _items.map((item) => item.toJson()).toList(),
      }),
    );
    if (!saved) throw StateError('Changes could not be saved. Try again.');
  }

  Future<void> configure(String name, String url) async {
    final oldName = business;
    final oldUrl = endpoint;
    business = name.trim();
    endpoint = url.trim().replaceAll(RegExp(r'/+$'), '');
    try {
      await _persist();
    } catch (_) {
      business = oldName;
      endpoint = oldUrl;
      rethrow;
    }
    notifyListeners();
  }

  Future<void> saveItem(StockItem item) async {
    final old = List<StockItem>.from(_items);
    final index = _items.indexWhere((entry) => entry.id == item.id);
    if (index < 0) {
      _items.add(item);
    } else {
      _items[index] = item;
    }
    try {
      await _persist();
    } catch (_) {
      _items
        ..clear()
        ..addAll(old);
      rethrow;
    }
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    final old = List<StockItem>.from(_items);
    _items.removeWhere((item) => item.id == id);
    try {
      await _persist();
    } catch (_) {
      _items
        ..clear()
        ..addAll(old);
      rethrow;
    }
    notifyListeners();
  }

  Future<void> changeStock(String id, int quantity,
      {required bool delivery}) async {
    if (quantity <= 0 || quantity > 1000000) {
      throw StateError('Enter 1–1000000 whole units.');
    }
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('This product no longer exists.');
    final item = _items[index];
    if (!delivery && quantity > item.stock) {
      throw StateError('You only have ${item.stock} units available.');
    }
    final next = item.stock + (delivery ? quantity : -quantity);
    if (next > 1000000) throw StateError('Stock cannot exceed 1000000 units.');
    final history =
        List<dynamic>.from(item.values['stock_activity'] as List? ?? []);
    history.insert(0, {
      'kind': delivery ? 'Received' : 'Sold',
      'units': quantity,
      'at': DateTime.now().toIso8601String(),
      'balance': next
    });
    await saveItem(StockItem(id: id, values: {
      ...item.values,
      'inventory': next,
      'stock_activity': history.take(20).toList()
    }));
  }

  Future<void> forecast(StockItem item) async {
    if (busyId != null) return;
    if (endpoint.isEmpty) {
      throw StateError('Add your forecast service in Settings.');
    }
    const required = [
      'store_type',
      'competitor_price',
      'discount',
      'previous_week_sales',
      'previous_month_sales',
      'temperature',
      'rainfall_mm',
      'season',
      'promotion',
      'holiday',
    ];
    if (required.any((key) => !item.values.containsKey(key))) {
      throw StateError('Complete forecast inputs in Edit product first.');
    }
    busyId = item.id;
    notifyListeners();
    try {
      final date = DateTime.parse(item.values['date'] as String);
      const days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final input = Map<String, dynamic>.from(item.values)
        ..remove('date')
        ..remove('reorder_point')
        ..addAll({
          'year': date.year,
          'month': date.month,
          'day': date.day,
          'day_of_week': days[date.weekday - 1],
          'weekend': date.weekday >= 6 ? 'Yes' : 'No',
        });
      final response = await client
          .post(
            Uri.parse('$endpoint/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(input),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        if (response.statusCode == 400) {
          throw StateError('Check the product details and try again.');
        }
        throw StateError('Forecast service is unavailable. Try again later.');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      for (final key in [
        'expected_demand',
        'restock_quantity',
        'recommended_inventory',
      ]) {
        if (data[key] is! num ||
            !(data[key] as num).isFinite ||
            (data[key] as num) < 0) {
          throw StateError('The forecast could not be read. Please try again.');
        }
      }
      // Do not attach a response to an item edited or removed during the request.
      if (!_items.contains(item)) return;
      final previous = item.forecast;
      item.forecast = {
        ...data,
        'generated_at': DateTime.now().toIso8601String(),
      };
      try {
        await _persist();
      } catch (_) {
        item.forecast = previous;
        rethrow;
      }
    } on StateError {
      rethrow;
    } catch (_) {
      throw StateError(
        'Could not reach the forecast service. Check your connection.',
      );
    } finally {
      busyId = null;
      notifyListeners();
    }
  }

  Future<void> planOrder(StockItem item) async {
    final sales = item.values['previous_week_sales'];
    if (sales is! num ||
        !sales.isFinite ||
        sales < 0 ||
        sales != sales.roundToDouble()) {
      throw StateError('Add units sold in the last 7 days first.');
    }
    final target = (sales * 1.2).ceil();
    final order = target > item.stock ? target - item.stock : 0;
    final old = item.forecast;
    item.forecast = {
      'expected_demand': sales.toInt(),
      'recommended_inventory': target,
      'restock_quantity': order,
      'generated_at': DateTime.now().toIso8601String(),
      'method': 'last_7_days',
      'horizon_days': 7,
    };
    try {
      await _persist();
    } catch (_) {
      item.forecast = old;
      rethrow;
    }
    notifyListeners();
  }

  Future<void> addSamples() async {
    if (_items.any((item) => item.values['sample'] == true)) return;
    final before = List<StockItem>.from(_items);
    final oldBusiness = business;
    if (!ready) business = 'Sample shop';
    final stamp = DateTime.now().microsecondsSinceEpoch;
    for (var i = 0; i < 3; i++) {
      _items.add(StockItem(id: 'sample-$stamp-$i', values: {
        'sample': true,
        'product': [
          'Product A · Rice 1 kg',
          'Product B · Milk 1 L',
          'Product C · Soap'
        ][i],
        'store': 'Sample branch',
        'area': 'Anna Nagar, Chennai',
        'category': 'Groceries',
        'inventory': [12, 6, 45][i],
        'reorder_point': [15, 10, 10][i],
        'price': [65, 60, 35][i],
        'cost_price': [50, 48, 25][i],
        'previous_week_sales': [28, 42, 14][i],
        'date': DateTime.now().toIso8601String().substring(0, 10),
      }));
    }
    try {
      await _persist();
    } catch (_) {
      _items
        ..clear()
        ..addAll(before);
      business = oldBusiness;
      rethrow;
    }
    notifyListeners();
  }

  Future<void> removeSamples() async {
    final before = List<StockItem>.from(_items);
    _items.removeWhere((item) => item.values['sample'] == true);
    try {
      await _persist();
    } catch (_) {
      _items
        ..clear()
        ..addAll(before);
      rethrow;
    }
    notifyListeners();
  }
}
