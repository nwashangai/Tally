import '../store/store_id.dart';
import 'item_id.dart';
import 'item_inventory.dart';
import 'item_pricing.dart';
import 'item_unit.dart';

/// Pure domain entity representing an Item in the store's inventory catalog.
///
/// **Domain Principle (ADR 0012)**:
/// "Current values belong to the Item; historical values belong to transactions/receivings."
class Item {
  final ItemId id;
  final StoreId storeId;
  final String name;
  final String? sku;
  final String? barcode;
  final String? description;
  final String? categoryId;
  final ItemUnit unit;
  final ItemPricing pricing;
  final ItemInventory inventory;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool hasTransactions;

  const Item({
    required this.id,
    required this.storeId,
    required this.name,
    this.sku,
    this.barcode,
    this.description,
    this.categoryId,
    this.unit = ItemUnit.piece,
    required this.pricing,
    required this.inventory,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.hasTransactions = false,
  });

  Item copyWith({
    ItemId? id,
    StoreId? storeId,
    String? name,
    String? sku,
    String? barcode,
    String? description,
    String? categoryId,
    ItemUnit? unit,
    ItemPricing? pricing,
    ItemInventory? inventory,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? hasTransactions,
  }) {
    return Item(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      unit: unit ?? this.unit,
      pricing: pricing ?? this.pricing,
      inventory: inventory ?? this.inventory,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hasTransactions: hasTransactions ?? this.hasTransactions,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id.value,
        'storeId': storeId.value,
        'name': name,
        'sku': sku,
        'barcode': barcode,
        'description': description,
        'categoryId': categoryId,
        'unit': unit.value,
        'pricing': pricing.toJson(),
        'inventory': inventory.toJson(),
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'hasTransactions': hasTransactions,
      };

  factory Item.fromJson(Map<String, Object?> json) {
    return Item(
      id: ItemId(json['id']! as String),
      storeId: StoreId(json['storeId']! as String),
      name: json['name']! as String,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      description: json['description'] as String?,
      categoryId: json['categoryId'] as String?,
      unit: ItemUnit.fromString(json['unit'] as String?),
      pricing: json['pricing'] is Map<String, Object?>
          ? ItemPricing.fromJson(json['pricing']! as Map<String, Object?>)
          : ItemPricing(
              costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
              baseSellingPrice:
                  (json['baseSellingPrice'] as num?)?.toDouble() ?? 0.0,
              minSellingPrice: (json['minSellingPrice'] as num?)?.toDouble(),
            ),
      inventory: json['inventory'] is Map<String, Object?>
          ? ItemInventory.fromJson(json['inventory']! as Map<String, Object?>)
          : ItemInventory(
              quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
              reorderLevel: (json['reorderLevel'] as num?)?.toDouble(),
            ),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt']! as String),
      updatedAt: DateTime.parse(json['updatedAt']! as String),
      hasTransactions: json['hasTransactions'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Item &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          storeId == other.storeId &&
          name == other.name &&
          sku == other.sku &&
          barcode == other.barcode &&
          categoryId == other.categoryId &&
          unit == other.unit &&
          pricing == other.pricing &&
          inventory == other.inventory &&
          isActive == other.isActive;

  @override
  int get hashCode => Object.hash(
        id,
        storeId,
        name,
        sku,
        barcode,
        categoryId,
        unit,
        pricing,
        inventory,
        isActive,
      );

  @override
  String toString() =>
      'Item(id: ${id.value}, name: $name, sku: $sku, qty: ${inventory.quantity} ${unit.abbreviation}, price: ${pricing.baseSellingPrice})';
}
