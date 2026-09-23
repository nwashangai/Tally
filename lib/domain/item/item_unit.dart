/// Standard measurement units for inventory items.
enum ItemUnit {
  piece('piece', 'pcs', 'Pieces'),
  bottle('bottle', 'btl', 'Bottles'),
  can('can', 'can', 'Cans'),
  box('box', 'box', 'Boxes'),
  carton('carton', 'ctn', 'Cartons'),
  pack('pack', 'pk', 'Packs'),
  bag('bag', 'bag', 'Bags'),
  dozen('dozen', 'dz', 'Dozens'),
  pair('pair', 'pr', 'Pairs'),
  roll('roll', 'roll', 'Rolls'),
  kg('kg', 'kg', 'Kilograms'),
  g('g', 'g', 'Grams'),
  litre('litre', 'L', 'Litres'),
  ml('ml', 'ml', 'Millilitres'),
  meter('meter', 'm', 'Meters');

  final String value;
  final String abbreviation;
  final String label;

  const ItemUnit(this.value, this.abbreviation, this.label);

  static ItemUnit fromString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return ItemUnit.piece;
    final normalized = raw.trim().toLowerCase();
    for (final unit in ItemUnit.values) {
      if (unit.value == normalized ||
          unit.abbreviation.toLowerCase() == normalized ||
          unit.name.toLowerCase() == normalized) {
        return unit;
      }
    }
    return ItemUnit.piece;
  }
}
