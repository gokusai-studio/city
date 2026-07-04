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
}
