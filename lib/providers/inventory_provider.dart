import 'package:flutter/material.dart';
import '../models/inventory_item.dart';

/// Supplies the dummy inventory list plus simple search/filter state.
class InventoryProvider extends ChangeNotifier {
  String _query = '';
  String _filter = 'All'; // All, Good, Low, Critical

  final List<InventoryItem> _items = const [
    InventoryItem(
      id: 'P001',
      productName: 'Wireless Earbuds',
      category: 'Electronics',
      currentStock: 340,
      predictedDemand: 320,
      status: 'Good',
    ),
    InventoryItem(
      id: 'P002',
      productName: 'Cotton T-Shirt',
      category: 'Apparel',
      currentStock: 120,
      predictedDemand: 540,
      status: 'Critical',
    ),
    InventoryItem(
      id: 'P003',
      productName: 'Travel Mug',
      category: 'Home & Living',
      currentStock: 210,
      predictedDemand: 160,
      status: 'Good',
    ),
    InventoryItem(
      id: 'P004',
      productName: 'Running Shoes',
      category: 'Apparel',
      currentStock: 95,
      predictedDemand: 130,
      status: 'Low',
    ),
    InventoryItem(
      id: 'P005',
      productName: 'Smart Watch',
      category: 'Electronics',
      currentStock: 48,
      predictedDemand: 150,
      status: 'Critical',
    ),
    InventoryItem(
      id: 'P006',
      productName: 'Backpack',
      category: 'Accessories',
      currentStock: 260,
      predictedDemand: 190,
      status: 'Good',
    ),
    InventoryItem(
      id: 'P007',
      productName: 'Bluetooth Speaker',
      category: 'Electronics',
      currentStock: 88,
      predictedDemand: 120,
      status: 'Low',
    ),
    InventoryItem(
      id: 'P008',
      productName: 'Yoga Mat',
      category: 'Fitness',
      currentStock: 175,
      predictedDemand: 100,
      status: 'Good',
    ),
    InventoryItem(
      id: 'P009',
      productName: 'Instant Noodles Pack',
      category: 'Groceries',
      currentStock: 60,
      predictedDemand: 400,
      status: 'Critical',
    ),
    InventoryItem(
      id: 'P010',
      productName: 'Desk Lamp',
      category: 'Home & Living',
      currentStock: 140,
      predictedDemand: 110,
      status: 'Good',
    ),
  ];

  String get query => _query;
  String get filter => _filter;

  List<InventoryItem> get items {
    return _items.where((item) {
      final matchesQuery =
          item.productName.toLowerCase().contains(_query.toLowerCase());
      final matchesFilter = _filter == 'All' || item.status == _filter;
      return matchesQuery && matchesFilter;
    }).toList();
  }

  int get goodCount => _items.where((e) => e.status == 'Good').length;
  int get lowCount => _items.where((e) => e.status == 'Low').length;
  int get criticalCount => _items.where((e) => e.status == 'Critical').length;

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setFilter(String value) {
    _filter = value;
    notifyListeners();
  }
}
