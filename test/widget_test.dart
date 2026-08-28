import 'package:flutter_test/flutter_test.dart';
import 'package:retail_inventory_ai/models/prediction_result.dart';

void main() {
  test('PredictionResult parses the backend response correctly', () {
    final result = PredictionResult.fromJson(
      store: 'Downtown Store',
      product: 'Wireless Earbuds',
      json: {
        'expected_demand': 320,
        'current_inventory': 300,
        'safety_stock': 38,
        'recommended_inventory': 358,
        'restock_quantity': 58,
        'surplus_quantity': 0,
        'stock_status': 'Low',
        'risk_level': 'High',
        'demand_change': 140,
        'demand_change_percentage': 77.78,
        'business_advice': 'Order additional stock.',
        'demand_factors': ['Active promotion'],
        'confidence': 0.91,
      },
    );

    expect(result.store, 'Downtown Store');
    expect(result.product, 'Wireless Earbuds');
    expect(result.expectedDemand, 320);
    expect(result.restockQuantity, 58);
    expect(result.requiresRestock, isTrue);
    expect(result.hasSurplus, isFalse);
    expect(result.confidenceLabel, '91.0%');
  });
}
