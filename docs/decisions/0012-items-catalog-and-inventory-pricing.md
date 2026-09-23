# 12. Items Catalog, Pricing Invariants & Inventory Ledger Distinction

Date: 2026-09-23

## Status

Accepted

## Context

Tally is a small-business inventory and sales record book. The Items module serves as the central catalog of products that a store buys, holds, and sells.

A fundamental design challenge in inventory accounting is distinguishing between an item's **current shelf values** (e.g. current replacement cost, recommended retail selling price, and minimum negotiated floor price) and **historical transaction records** (e.g., unit cost paid on past purchase orders or historical prices charged at checkout). Overwriting past transaction costs when an item's current cost changes corrupts financial ledgers and stock valuation reports.

Furthermore, accidental deletion of catalog items referenced by historical receipts or sales would violate relational integrity and historical accounting.

## Decision

1. **Strict Separation of Current vs Historical Values**:
   - The `Item` domain aggregate stores current shelf attributes: `costPrice`, `baseSellingPrice`, `minSellingPrice`, `quantity`, and `reorderLevel`.
   - Historical transactions (`Receiving`, `Sale`, `StockMovement`) immutably record the exact unit cost and unit price at the time of execution.
   - Modifying an Item's current prices or quantity never mutates past transaction records.

2. **Domain Pricing Invariants**:
   - `costPrice >= 0` and `baseSellingPrice >= 0`.
   - When a `minSellingPrice` (floor price) is defined, it must strictly satisfy `minSellingPrice <= baseSellingPrice`. This invariant is enforced in `ItemPricing` upon construction and validated across UI forms.

3. **Safe Delete vs Archive Lifecycle**:
   - `ItemRepository.delete(ItemId id)` queries the transaction ledger. If any historical records reference the item, permanent deletion is blocked with a domain error.
   - The user is guided to **Archive** the item (`is_active = 0`), hiding it from active POS registers and lists while preserving ledger history.
   - Items with zero recorded transactions can be permanently removed from SQLite.

4. **High-Performance Querying & Indexing**:
   - Local Drift/SQLite queries use database-level filtering, search (`LIKE`), and pagination (`COUNT(*)` + `LIMIT / OFFSET`) to maintain 60fps performance on 50,000+ items.
   - Compound indexes are established on `(store_id, name)`, `(store_id, sku)`, `(store_id, barcode)`, `(store_id, category_id)`, `(store_id, is_active)`, and `(store_id, updated_at)`.

5. **Extensible Export Infrastructure**:
   - `ItemExportService` orchestrates exports with scope options (`currentView`, `selectedItems`, `allItems`).
   - `ExcelItemExporter` produces genuine `.xlsx` workbooks with auto-fit columns, headers, and numeric types.
   - `CsvItemExporter` produces RFC 4180 UTF-8 with BOM for cross-platform compatibility.

## Consequences

- Financial records remain 100% auditable and mathematically consistent across price fluctuations.
- Fast, low-memory catalog navigation on mobile, tablet, and desktop devices.
- Seamless foundation for forthcoming Receivings, Inventory Stock Movements, and POS Register modules.
