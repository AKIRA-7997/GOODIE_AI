import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/prediction_result.dart';

class PredictionProvider extends ChangeNotifier {
  final List<String> stores = const [
    'Downtown Store',
    'Mall Outlet',
    'Airport Kiosk',
    'Suburban Branch',
    'Online Warehouse',
  ];

  final List<String> products = const [
    'Wireless Earbuds',
    'Cotton T-Shirt',
    'Travel Mug',
    'Running Shoes',
    'Smart Watch',
    'Backpack',
  ];

  String? selectedStore;
  String? selectedProduct;

  double price = 49.99;
  double discount = 10;
  bool isHoliday = false;
  double temperature = 28;
  bool hasPromotion = true;

  bool isLoading = false;
  String? errorMessage;
  PredictionResult? result;

  void setStore(String? value) {
    selectedStore = value;
    notifyListeners();
  }

  void setProduct(String? value) {
    selectedProduct = value;
    notifyListeners();
  }

  void setPrice(double value) {
    price = value;
    notifyListeners();
  }

  void setDiscount(double value) {
    discount = value;
    notifyListeners();
  }

  void setHoliday(bool value) {
    isHoliday = value;
    notifyListeners();
  }

  void setTemperature(double value) {
    temperature = value;
    notifyListeners();
  }

  void setPromotion(bool value) {
    hasPromotion = value;
    notifyListeners();
  }

  bool get canPredict =>
      selectedStore != null &&
          selectedProduct != null &&
          !isLoading;

  Future<void> predict() async {
    if (!canPredict) return;

    isLoading = true;
    errorMessage = null;
    result = null;
    notifyListeners();

    try {
      final now = DateTime.now();

      final uri = Uri.parse('http://10.0.2.2:5000/predict');

      final response = await http
          .post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'store': selectedStore,
          'store_type': _storeTypeFor(selectedStore!),
          'product': selectedProduct,
          'category': _categoryFor(selectedProduct!),
          'price': price,
          'cost_price': price * 0.65,
          'discount': discount,
          'holiday': isHoliday ? 'Yes' : 'No',
          'weekend': _isWeekend(now) ? 'Yes' : 'No',
          'day_of_week': _dayName(now.weekday),
          'month': now.month,
          'season': _seasonForMonth(now.month),
          'temperature': temperature,
          'rainfall_mm': 0,
          'promotion': hasPromotion ? 'Active' : 'None',
          'competitor_price': price * 1.05,
          'inventory': 300,
          'previous_week_sales': 180,
          'previous_month_sales': 720,
          'year': now.year,
          'day': now.day,
        }),
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
          'Server error ${response.statusCode}: ${response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      result = PredictionResult.fromJson(
        json: data,
        store: selectedStore!,
        product: selectedProduct!,
      );
    } catch (error) {
      errorMessage = error.toString();
      debugPrint('Prediction failed: $error');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    result = null;
    errorMessage = null;
    notifyListeners();
  }

  String _storeTypeFor(String store) {
    switch (store) {
      case 'Mall Outlet':
        return 'Mall';
      case 'Airport Kiosk':
        return 'Kiosk';
      case 'Online Warehouse':
        return 'Warehouse';
      case 'Suburban Branch':
        return 'Suburban';
      default:
        return 'Urban';
    }
  }

  String _categoryFor(String product) {
    switch (product) {
      case 'Wireless Earbuds':
      case 'Smart Watch':
        return 'Electronics';
      case 'Cotton T-Shirt':
      case 'Running Shoes':
        return 'Fashion';
      case 'Travel Mug':
        return 'Home';
      case 'Backpack':
        return 'Accessories';
      default:
        return 'General';
    }
  }

  bool _isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday ||
        date.weekday == DateTime.sunday;
  }

  String _dayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return days[weekday - 1];
  }

  String _seasonForMonth(int month) {
    if (month >= 3 && month <= 5) return 'Summer';
    if (month >= 6 && month <= 9) return 'Monsoon';
    if (month >= 10 && month <= 11) return 'Autumn';
    return 'Winter';
  }
}