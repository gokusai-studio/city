/// 課金SDKは現在ビルド互換性を検証中のため一時的に無効化しています。
/// (v0.4以降で再導入予定)
class IapService {
  static const String removeAdsId = 'remove_ads_nonconsumable';
  static const String fundsPackSmallId = 'funds_pack_small_consumable';

  List<dynamic> products = [];
  bool adsRemoved = false;

  Future<bool> init() async => false;

  Future<void> buy(String productId) async {}

  void dispose() {}
}    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        if (purchase.productID == removeAdsId) {
          adsRemoved = true;
        }
        // funds_pack_small は購入確認後に呼び出し側(UI)で資金加算処理を行う
        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase);
        }
      }
    }
  }

  Future<void> buy(String productId) async {
    ProductDetails? product;
    for (final p in products) {
      if (p.id == productId) {
        product = p;
        break;
      }
    }
    if (product == null) return;
    final param = PurchaseParam(productDetails: product);
    if (productId == fundsPackSmallId) {
      await _iap.buyConsumable(purchaseParam: param);
    } else {
      await _iap.buyNonConsumable(purchaseParam: param);
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
