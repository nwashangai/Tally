/// Configurable columns for the Items data table and exports.
enum ItemColumn {
  name('Item', 'Product / item name', true),
  sku('SKU', 'Stock keeping unit', false),
  barcode('Barcode', 'EAN/UPC barcode number', false),
  category('Category', 'Item department/category', false),
  unit('Unit', 'Measurement unit', false),
  stock('Stock', 'Current on-hand quantity', false),
  reorderLevel(
      'Reorder Level', 'Minimum threshold for low stock alerts', false),
  costPrice('Cost Price', 'Current unit acquisition cost', false),
  baseSellingPrice('Selling Price', 'Base retail selling price', false),
  minSellingPrice(
      'Min Price', 'Lowest permissible negotiated selling price', false),
  margin('Margin', 'Gross profit margin (Selling - Cost)', false),
  status('Status', 'Active / Archived flag', false),
  updatedAt('Last Updated', 'Timestamp of last modification', false);

  final String label;
  final String description;
  final bool isMandatory;

  const ItemColumn(this.label, this.description, this.isMandatory);

  static ItemColumn? fromString(String raw) {
    for (final col in ItemColumn.values) {
      if (col.name == raw) return col;
    }
    return null;
  }
}

/// Predefined column presets for fast switching.
enum ColumnPreset {
  standard('Default', 'Essential fields for general inventory browsing'),
  pricing('Pricing',
      'Focus on acquisition costs, retail pricing, and profit margins'),
  stock('Stock & Units',
      'Focus on quantities, categories, units, and reorder levels'),
  full('Full Details', 'Displays all available item attributes');

  final String label;
  final String description;

  const ColumnPreset(this.label, this.description);

  Set<ItemColumn> get columns {
    switch (this) {
      case ColumnPreset.standard:
        return {
          ItemColumn.name,
          ItemColumn.sku,
          ItemColumn.stock,
          ItemColumn.costPrice,
          ItemColumn.baseSellingPrice,
          ItemColumn.minSellingPrice,
          ItemColumn.status,
        };
      case ColumnPreset.pricing:
        return {
          ItemColumn.name,
          ItemColumn.costPrice,
          ItemColumn.baseSellingPrice,
          ItemColumn.minSellingPrice,
          ItemColumn.margin,
          ItemColumn.updatedAt,
        };
      case ColumnPreset.stock:
        return {
          ItemColumn.name,
          ItemColumn.category,
          ItemColumn.unit,
          ItemColumn.stock,
          ItemColumn.reorderLevel,
          ItemColumn.status,
        };
      case ColumnPreset.full:
        return ItemColumn.values.toSet();
    }
  }
}
