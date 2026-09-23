import 'package:flutter_test/flutter_test.dart';
import 'package:tally/domain/item/item.dart';
import 'package:tally/domain/item/item_id.dart';
import 'package:tally/domain/item/item_inventory.dart';
import 'package:tally/domain/item/item_pricing.dart';
import 'package:tally/domain/item/item_unit.dart';
import 'package:tally/domain/store/store_id.dart';

void main() {
  group('ItemPricing', () {
    test('constructs valid pricing and calculates margin and markup', () {
      final pricing = ItemPricing(
        costPrice: 200,
        baseSellingPrice: 300,
        minSellingPrice: 250,
      );

      expect(pricing.costPrice, 200);
      expect(pricing.baseSellingPrice, 300);
      expect(pricing.minSellingPrice, 250);
      expect(pricing.margin, 100);
      expect(pricing.markupPercentage, 50.0);
    });

    test('throws ArgumentError if minSellingPrice > baseSellingPrice', () {
      expect(
        () => ItemPricing(
          costPrice: 200,
          baseSellingPrice: 250,
          minSellingPrice: 300, // Invalid: exceeds base
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError on negative prices', () {
      expect(
        () => ItemPricing(costPrice: -10, baseSellingPrice: 100),
        throwsArgumentError,
      );
      expect(
        () => ItemPricing(costPrice: 10, baseSellingPrice: -5),
        throwsArgumentError,
      );
      expect(
        () => ItemPricing(
          costPrice: 10,
          baseSellingPrice: 20,
          minSellingPrice: -1,
        ),
        throwsArgumentError,
      );
    });

    test('allows minSellingPrice == baseSellingPrice', () {
      final pricing = ItemPricing(
        costPrice: 100,
        baseSellingPrice: 150,
        minSellingPrice: 150,
      );
      expect(pricing.minSellingPrice, 150);
    });

    test('serializes and deserializes via toJson / fromJson', () {
      final pricing = ItemPricing(
        costPrice: 220,
        baseSellingPrice: 270,
        minSellingPrice: 250,
      );
      final json = pricing.toJson();
      final restored = ItemPricing.fromJson(json);

      expect(restored, equals(pricing));
    });
  });

  group('ItemInventory', () {
    test('calculates stock health correctly', () {
      final healthy = ItemInventory(quantity: 50, reorderLevel: 10);
      expect(healthy.isInStock, isTrue);
      expect(healthy.isLowStock, isFalse);
      expect(healthy.isOutOfStock, isFalse);

      final lowStock = ItemInventory(quantity: 8, reorderLevel: 10);
      expect(lowStock.isInStock, isFalse);
      expect(lowStock.isLowStock, isTrue);
      expect(lowStock.isOutOfStock, isFalse);

      final outOfStock = ItemInventory(quantity: 0, reorderLevel: 10);
      expect(outOfStock.isInStock, isFalse);
      expect(outOfStock.isLowStock, isFalse);
      expect(outOfStock.isOutOfStock, isTrue);
    });

    test('throws ArgumentError on negative reorder level', () {
      expect(
        () => ItemInventory(quantity: 10, reorderLevel: -5),
        throwsArgumentError,
      );
    });
  });

  group('Item Entity', () {
    test('full round-trip json serialization and equality', () {
      final now = DateTime.utc(2026, 9, 23, 10, 0, 0);
      final item = Item(
        id: const ItemId('item-123'),
        storeId: const StoreId('store-456'),
        name: 'Coca-Cola 50cl',
        sku: 'COKE-50',
        barcode: '5449000000996',
        description: 'Refreshing carbonated soft drink',
        categoryId: 'Drinks',
        unit: ItemUnit.bottle,
        pricing: ItemPricing(
          costPrice: 200,
          baseSellingPrice: 250,
          minSellingPrice: 240,
        ),
        inventory: ItemInventory(quantity: 42, reorderLevel: 12),
        isActive: true,
        createdAt: now,
        updatedAt: now,
        hasTransactions: true,
      );

      final json = item.toJson();
      final restored = Item.fromJson(json);

      expect(restored.id, item.id);
      expect(restored.storeId, item.storeId);
      expect(restored.name, item.name);
      expect(restored.sku, item.sku);
      expect(restored.unit, ItemUnit.bottle);
      expect(restored.pricing.costPrice, 200);
      expect(restored.pricing.baseSellingPrice, 250);
      expect(restored.pricing.minSellingPrice, 240);
      expect(restored.inventory.quantity, 42);
      expect(restored.inventory.reorderLevel, 12);
      expect(restored.hasTransactions, isTrue);
    });
  });
}
