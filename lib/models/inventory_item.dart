/// Represents a single product row in the inventory table.
class InventoryItem {
  final String id;
  final String productName;
  final String category;
  final int currentStock;
  final int predictedDemand;
  final String status; // Good, Low, Critical

  const InventoryItem({
    required this.id,
    required this.productName,
    required this.category,
    required this.currentStock,
    required this.predictedDemand,
    required this.status,
  });
}
