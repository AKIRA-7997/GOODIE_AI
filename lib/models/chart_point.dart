/// Generic labeled data point used across line/bar charts.
class ChartPoint {
  final String label;
  final double value;

  const ChartPoint(this.label, this.value);
}

/// Category share used for pie / distribution charts.
class CategorySlice {
  final String label;
  final double value;
  final int colorIndex;

  const CategorySlice(this.label, this.value, this.colorIndex);
}
