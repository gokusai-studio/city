import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

/// アプリ内課金（資金パック・広告非表示等）の基本サービス。
/// MVPでは「広告非表示（非消費型）」と「資金パック(消費型)」の2種類を想定。
///
/// ⚠️ 商品ID(_productIds)はGoogle Play Consoleの「商品」設定で
/// 実際に作成したIDと完全一致させる必要がある。ここでは仮IDを置いている。
class IapService {
  static const String removeAdsId = 'remove_ads_nonconsumable';
  static const String fundsPackSmallId = 'funds_pack_small_consumable';

  static const Set<String> _productIds = {removeAdsId, fundsPackSmallId};

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  List<ProductDetails> products = [];
  bool adsRemoved = false;

  Future<bool> init() async {
    final available = await _iap.isAvailable();
    if (!available) return false;

    final response = await _iap.queryProductDetails(_productIds);
    products = response.productDetails;

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (_) {},
    );
    return true;
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
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
