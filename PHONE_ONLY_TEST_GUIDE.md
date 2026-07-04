# スマホだけでテストプレイする方法（PC不要）

GitHubの「GitHub Actions」というサービスにビルド作業を代行してもらい、
できあがったAPKファイルをスマホにダウンロードしてインストールする方法です。
所要時間の目安：初回セットアップ15〜20分、その後のビルド待ちは5〜10分。

---

## 方法A：GitHub Codespaces を使う（推奨・一番ラクな方法）

1. スマホのブラウザで https://github.com を開き、ログイン
2. 右上の「+」→「New repository」で空のリポジトリを作成
   - Repository name: `hakata-city-sim` など好きな名前
   - Public / Private どちらでもOK（Privateでも無料でActionsは使えます）
   - 「Add a README file」にチェックを入れて作成
3. 作成したリポジトリ画面で、上部のブランチ選択の近くにある「Code」ボタン→
   「Codespaces」タブ→「Create codespace on main」をタップ
   - ブラウザ上でVS Codeのような開発画面が開きます（これがPCの代わりになります）
4. Codespace内の左側「エクスプローラー」を右クリック（長押し）→
   「Upload...」を選択
5. あらかじめスマホのダウンロードフォルダに保存しておいた
   `hakata_city_sim.zip` を選んでアップロード
6. 画面下の「ターミナル」を開き（メニュー: Terminal → New Terminal）、
   以下を実行してzipを展開し、中身をルートへ移動：
   ```bash
   unzip hakata_city_sim.zip
   shopt -s dotglob
   mv hakata_city_sim/* .
   rm -rf hakata_city_sim hakata_city_sim.zip
   ls -a
   ```
   (`lib`, `pubspec.yaml`, `.github` などがリポジトリ直下に見えていればOK)
7. ターミナルで以下を実行してGitHubへ反映：
   ```bash
   git add .
   git commit -m "add hakata city sim source"
   git push
   ```
8. リポジトリの「Actions」タブを開くと、自動でビルドが始まっています
   （初回はFlutterのセットアップも走るので5〜10分程度かかります）
9. ビルドが緑色のチェックで完了したら、その実行結果ページ下部の
   「Artifacts」欄にある `hakata-city-sim-apk` をタップしてダウンロード
   （zip形式でダウンロードされます）

---

## 方法B：ブラウザだけで1ファイルずつアップロードする（Codespacesが使えない場合）

1. 空のリポジトリを作成（方法Aの手順1-2と同じ）
2. リポジトリ画面で「Add file」→「Create new file」
3. ファイル名の欄に、フォルダごと `.github/workflows/build-apk.yml` と
   入力する（スラッシュを入れると自動でフォルダが作られます）
4. 本zip内の `.github/workflows/build-apk.yml` の中身をコピーして貼り付け→
   「Commit new file」
5. 同様に `pubspec.yaml`、`lib/main.dart`、`lib/app/app.dart` …と
   すべてのファイルを1つずつ「Create new file」で作成していく
   （地道ですが、ファイルの中身をこちらのチャットからコピペしていただければ
   すべて再現可能です。必要であれば全ファイルの中身をこの後まとめて
   貼り出しますので、その旨お知らせください）
6. 全ファイルを反映したら、方法Aの手順8以降と同じ

---

## APKをスマホにインストールする

1. ダウンロードした `hakata-city-sim-apk.zip` を、スマホの標準の
   「ファイル」アプリ（または任意の解凍アプリ）で展開し、
   `app-release.apk` を取り出す
2. `app-release.apk` をタップ
3. 初回は「このソースからのアプリを許可しますか」といった確認画面が出るので、
   使用中のブラウザ/ファイルアプリに対して「許可」する
   （Android設定 → アプリ → 特別なアクセス → 不明なアプリのインストール、から
   手動で許可することもできます）
4. インストール完了後、ホーム画面から「HAKATA RISING」を起動

## 注意点
- このAPKは「署名なし（Flutterのデバッグ鍵で自動署名）」のテスト専用ビルドです。
  動作確認はできますが、このままではGoogle Playには公開できません
  （公開用ビルドの作り方は `RELEASE_GUIDE.md` を参照）
- 毎回コードを修正してpushするたびに、Actionsタブから新しいAPKが自動生成されます
- 広告(AdMob)はテストIDのままなので、テストプレイ中は本物の広告は出ず、
  Googleのテスト広告(枠)が表示されます
