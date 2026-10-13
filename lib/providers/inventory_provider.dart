import 'package:flutter/foundation.dart';

import '../core/constants/shop_catalog.dart';
import '../core/constants/storage_keys.dart';
import '../models/purchase_result.dart';
import '../models/seed_item.dart';
import '../models/tool_item.dart';
import '../services/storage_service.dart';
import 'user_provider.dart';

/// Seeds + tools the player owns. Purchases spend coins through [UserProvider].
class InventoryProvider extends ChangeNotifier {
  InventoryProvider(this._s, this._user) {
    for (final seed in ShopCatalog.seeds) {
      _counts[seed.id] = _s.getInt(StorageKeys.inventory(seed.id), 0);
    }
    for (final tool in ShopCatalog.tools) {
      _counts[tool.id] = _s.getInt(StorageKeys.inventory(tool.id), 0);
    }
  }

  final StorageService _s;
  final UserProvider _user;
  final Map<String, int> _counts = {};

  int count(String itemId) =>
      _counts[itemId] ??= _s.getInt(StorageKeys.inventory(itemId), 0);

  PurchaseResult buySeed(SeedItem seed, {bool bundle = false}) {
    final price = bundle ? seed.bundlePrice : seed.unitPrice;
    if (!_user.spendCoins(price)) return PurchaseResult.insufficientFunds;
    _add(seed.id, bundle ? SeedItem.bundleSize : 1);
    return PurchaseResult.success;
  }

  PurchaseResult buyTool(ToolItem tool) {
    if (!_user.spendCoins(tool.price)) return PurchaseResult.insufficientFunds;
    _add(tool.id, 1);
    return PurchaseResult.success;
  }

  /// Used by the Garden in Phase 3 (planting, watering, fertilizing, digging).
  bool consume(String itemId) {
    if (count(itemId) <= 0) return false;
    _counts[itemId] = count(itemId) - 1;
    _s.setInt(StorageKeys.inventory(itemId), _counts[itemId]!);
    notifyListeners();
    return true;
  }

  void _add(String itemId, int amount) {
    _counts[itemId] = count(itemId) + amount;
    _s.setInt(StorageKeys.inventory(itemId), _counts[itemId]!);
    notifyListeners();
  }
}
