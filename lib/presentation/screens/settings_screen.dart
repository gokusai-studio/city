import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/iap/iap_service.dart';
import '../../services/save/save_service.dart';
import '../providers/city_providers.dart';

/// 設定画面：課金導線・セーブ初期化・プライバシーポリシーへのリンクを集約。
/// 片手操作前提でシンプルな縦積みリストにしている。
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final IapService _iap = IapService();
  bool _iapReady = false;

  @override
  void initState() {
    super.initState();
    _iap.init().then((ok) => setState(() => _iapReady = ok));
  }

  @override
  void dispose() {
    _iap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('広告を非表示にする'),
            subtitle: Text(_iapReady ? '購入するとバナー広告が消えます' : 'ストアに接続できませんでした'),
            enabled: _iapReady,
            onTap: _iapReady ? () => _iap.buy(IapService.removeAdsId) : null,
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('資金パックを購入する'),
            subtitle: const Text('ゲーム内資金をすぐに補充します'),
            enabled: _iapReady,
            onTap: _iapReady
                ? () async {
                    await _iap.buy(IapService.fundsPackSmallId);
                    final engine = ref.read(gameLoopEngineProvider);
                    engine.city.funds += 5000; // 購入確定後の付与（本来はレシート検証後）
                  }
                : null,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: const Text('セーブデータをリセット'),
            subtitle: const Text('この街の開発状況を最初からやり直します'),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('本当にリセットしますか？'),
                  content: const Text('これまでの開発状況は元に戻せません。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('リセットする'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await SaveService.clearSave();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('リセットしました。アプリを再起動してください。')),
                  );
                }
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('プライバシーポリシー'),
            subtitle: const Text('公開後、ここに配布用URLを設定してください'),
            onTap: () {
              // TODO: url_launcherを追加し、公開したプライバシーポリシーURLを開く
            },
          ),
        ],
      ),
    );
  }
}
