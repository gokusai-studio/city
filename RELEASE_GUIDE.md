# 公開準備・実行手順書

このドキュメントは「コードとして作成できるもの」と「あなたのアカウント・端末でしか
実行できないもの」を明確に分け、公開までの残タスクを最短経路で示します。

---

## 0. まず理解しておくこと（重要）

このプロジェクトは `lib/` フォルダと `pubspec.yaml` のみで構成されています。
Flutterの実行環境（SDK・ネットワーク）が使えない環境で作成したため、
`android/` `ios/` フォルダ等、`flutter create` で生成される「実機ビルド用の器」が
まだ存在しません。**最初に一度、あなたの手元でこの器を作る必要があります。**

これは10分程度で終わる機械的な作業です。以下の手順1で行います。

---

## 1. プロジェクトの器を作る（あなたの端末で実行・所要10分）

```bash
# 1. 空のFlutterプロジェクトを作成
flutter create --org com.yourcompany.hakatarising hakata_city_sim_full
cd hakata_city_sim_full

# 2. 今回作成した lib/ と pubspec.yaml の中身をコピーで上書き
#    (このzipファイルのlib/フォルダとpubspec.yamlの依存関係部分をマージしてください)
cp -r ../hakata_city_sim/lib/* lib/
cp ../hakata_city_sim/assets -r .

# pubspec.yamlは新規生成されたものに、今回のdependencies/assetsをマージしてください
# (nameやorg設定は`flutter create`で作られたものを優先)

# 3. 依存パッケージを取得
flutter pub get

# 4. 実機/エミュレータで動作確認
flutter run
```

## 2. AdMob用のアプリIDを設定する（あなたのAdMobアカウントで実行）

1. https://admob.google.com でアカウント作成 → アプリを登録
2. 発行された「アプリID」（ca-app-pub-xxxxxxxx~yyyyyyyy 形式）を取得
3. `android/app/src/main/AndroidManifest.xml` の `<application>` タグ内に追加：

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-あなたのアプリID"/>
```

4. `lib/presentation/widgets/banner_ad_widget.dart` 内の `_testAdUnitId` を、
   AdMobコンソールで発行した「広告ユニットID」に置き換える
   （テストIDのままだと収益が発生しません）

## 3. アプリ内課金の商品を設定する（Google Play Console側で実行）

Play Consoleの「収益化 > 商品 > アプリ内アイテム」で以下を作成：
- `remove_ads_nonconsumable`（非消費型）
- `funds_pack_small_consumable`（消費型）

※IDは `lib/services/iap/iap_service.dart` の定数と完全一致させてください。

## 4. 署名鍵を作る（あなたの端末で実行・厳重に保管）

```bash
keytool -genkey -v -keystore ~/hakata-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias hakata_key
```

`android/key.properties` を作成し、パスとパスワードを記載（Flutter公式ドキュメント
「Build and release an Android app」の手順に準拠）。
**このjksファイルとパスワードは紛失すると二度とアップデートを配信できなくなるため、
必ず安全な場所に複数バックアップしてください。**

## 5. リリースビルドを作る

```bash
flutter build appbundle --release
```

生成物：`build/app/outputs/bundle/release/app-release.aab`

## 6. プライバシーポリシーを公開する

`store_assets/privacy_policy_ja.md` の内容を編集し、HTML化して
一般公開URLに設置してください（GitHub Pagesが無料で簡単です）。

## 7. Google Play Consoleでの申請（あなたのアカウントで実行）

1. Google Play Console（年1回$25の登録料）でデベロッパーアカウント作成
2. 「アプリを作成」→ アプリ名・言語・アプリ/ゲーム区分を入力
3. ストアの掲載情報に `store_assets/store_listing_ja.md` の内容を転記
4. `store_assets/app_icon_512.png`、`feature_graphic_1024x500.png` をアップロード
   （※これらは簡易プレースホルダーです。本申請前にデザインツール等で
   ブラッシュアップすることを強く推奨します）
5. スクリーンショット（最低2枚、電話用は16:9か9:16）を実機/エミュレータから撮影して追加
6. プライバシーポリシーのURLを入力
7. コンテンツレーティングの質問票に回答（本ドキュメントの注意点を参照）
8. データセーフティのフォームに回答（保存データ・広告SDK・課金SDKの利用を正直に申告）
9. 内部テスト版としてaabをアップロードし、自分の端末で最終動作確認
10. 問題なければ「本番」トラックに昇格して審査提出

審査は通常数時間〜数日で完了します。

---

## チェックリスト（公開直前の最終確認）

- [ ] `flutter run`で実機動作確認済み
- [ ] AdMobの本番IDに置き換え済み
- [ ] IAP商品IDがPlay Consoleと一致
- [ ] 署名鍵(jks)をバックアップ済み
- [ ] プライバシーポリシーが実際に公開URLで閲覧できる
- [ ] コンテンツレーティング・データセーフティに正直に回答済み
- [ ] スクリーンショット・アイコン・フィーチャーグラフィックを本番用に差し替え済み
