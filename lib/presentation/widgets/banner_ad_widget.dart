import 'package:flutter/material.dart';

/// 広告SDKは現在ビルド互換性を検証中のため一時的に無効化しています。
/// (v0.4以降で再導入予定)
class BannerAdWidget extends StatelessWidget {
  const BannerAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          // 広告読み込み失敗はゲーム体験に影響させない（何も表示しないだけ）
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();
    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
