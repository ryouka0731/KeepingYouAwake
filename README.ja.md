# KeepingYouAwake (Amphetamine)

🌐 [English](README.md) · **日本語** · [简体中文](README.zh-CN.md) · [Deutsch](README.de.md) · [Français](README.fr.md)

> [`newmarcel/KeepingYouAwake`](https://github.com/newmarcel/KeepingYouAwake) のコミュニティフォーク (メンテナ: [@ryouka0731](https://github.com/ryouka0731))。慣れ親しんだ `caffeinate` ラッパーに **Amphetamine 風の機能** を追加。upstream メンテナの依頼に従い、アプリ名 (橙アイコン + サフィックス付き表示名) を本家と区別している。

KeepingYouAwake (Amphetamine) は macOS 10.13 以降向けの軽量メニューバーユーティリティ。事前に決めた時間 — または何らかのトリガが続く間 — Mac をスリープさせない。

## upstream 1.6.9 から追加された機能

| # | 機能 | PR |
|---|------|----|
| 1 | ディスクスリープ防止 (`caffeinate -m`) | [#8](https://github.com/ryouka0731/KeepingYouAwake/pull/8) |
| 2 | バッテリー満充電時に自動停止 | [#9](https://github.com/ryouka0731/KeepingYouAwake/pull/9) |
| 3 | アクティベーション時間: 今日いっぱい (次の真夜中まで) | [#10](https://github.com/ryouka0731/KeepingYouAwake/pull/10) |
| 4 | App Intents / Shortcuts.app 連携 (`Activate` / `Deactivate` / `Toggle`) | [#17](https://github.com/ryouka0731/KeepingYouAwake/pull/17) |
| 5 | トリガー: 指定 Wi-Fi SSID 接続中 | [#18](https://github.com/ryouka0731/KeepingYouAwake/pull/18) |
| 6 | トリガー: AC 電源接続中 (transition 認識) | [#19](https://github.com/ryouka0731/KeepingYouAwake/pull/19) |
| 7 | Drive Alive — アクティベーション中に外付けドライブの停止を防ぐ | [#20](https://github.com/ryouka0731/KeepingYouAwake/pull/20) |
| 8 | トリガー: 指定アプリ起動中 (複数 bundle 対応) | [#27](https://github.com/ryouka0731/KeepingYouAwake/pull/27) / [#28](https://github.com/ryouka0731/KeepingYouAwake/pull/28) |

加えて session source tracking を導入し、機能トリガーがユーザー手動セッションを誤って終了させない設計に refactor 済。

## インストール

### ダウンロード (推奨)

[Releases ページ →](https://github.com/ryouka0731/KeepingYouAwake/releases)

各リリースに `KeepingYouAwake-<tag>.dmg` と `.dmg.sha256` を添付。Apple Developer ID が無いため **ad-hoc 署名のみ・非公証**。初回起動は以下:

1. dmg をマウント、`KeepingYouAwake.app` を `/Applications` にドラッグ。
2. アプリを **右クリック → 開く** → ダイアログで「開く」を確定。
3. (もしくは初回起動失敗後、システム設定 → プライバシーとセキュリティ → このまま開く)

以降は通常起動。

### ソースからビルド

```bash
git clone https://github.com/ryouka0731/KeepingYouAwake.git
cd KeepingYouAwake
open KeepingYouAwake.xcworkspace
```

Xcode 16 以降で開いて Run (アイコンが Xcode 16 から導入された Icon Composer 形式のため)。macOS 10.13+ 対応。

## 新機能の設定

新機能のうち UI 未対応のものは `NSUserDefaults` に直接書き込み:

```bash
# 監視対象アプリの bundle ID 群 (いずれか起動中なら KYA active 維持)
defaults write info.marcel-dierkes.KeepingYouAwake \
  info.marcel-dierkes.KeepingYouAwake.WatchedApplicationBundleIdentifiers \
  -array com.apple.FinalCut com.apple.Logic

# 監視対象 Wi-Fi SSID (大文字小文字区別なし)
defaults write info.marcel-dierkes.KeepingYouAwake \
  info.marcel-dierkes.KeepingYouAwake.WatchedWiFiSSIDs \
  -array Office-WiFi Home-5G

# AC 電源接続中に自動 activate
defaults write info.marcel-dierkes.KeepingYouAwake \
  info.marcel-dierkes.KeepingYouAwake.ActivateOnACPowerEnabled -bool YES

# Drive Alive
defaults write info.marcel-dierkes.KeepingYouAwake \
  info.marcel-dierkes.KeepingYouAwake.DriveAliveEnabled -bool YES

# ディスクスリープ防止
defaults write info.marcel-dierkes.KeepingYouAwake \
  info.marcel-dierkes.KeepingYouAwake.PreventDiskSleepEnabled -bool YES

# 満充電時に停止
defaults write info.marcel-dierkes.KeepingYouAwake \
  info.marcel-dierkes.KeepingYouAwake.DeactivateOnFullChargeEnabled -bool YES
```

`keepingyouawake:///activate?seconds=N` / `:///deactivate` / `:///toggle` URL scheme は App Intents 経由で Shortcuts.app からも呼べる。

## 動作原理

macOS 標準の [`caffeinate`](https://web.archive.org/web/20140604153141/https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man8/caffeinate.8.html) に対する薄いラッパー。upstream の制約 (蓋を閉じた MacBook では macOS 自身がスリープを強制する等) は同じく適用される。

## upstream との関係

このフォークは `newmarcel/KeepingYouAwake` を追跡し、upstream のメンテナンス修正を取り込む。フォーク固有でないバグ修正は適切な場合 upstream に提案する。

オリジナルの `newmarcel/KeepingYouAwake` および `keepingyouawake.app` は引き続き [Marcel Dierkes 氏](https://github.com/newmarcel) のプロジェクト。

## bot レビュー / CI

- **CI** (`.github/workflows/ci.yml`) — 各 PR で xcodebuild build / SPM パッケージのユニットテスト / `caffeinate` プロセス起動を確認する URL scheme E2E。
- **Release** (`.github/workflows/release.yml`) — `v*` タグ push で Release config の dmg を ad-hoc 署名 + GitHub Release に upload。
- **CodeQL + OSSF Scorecards** — PR + 週次でセキュリティ監査。
- **AI レビュー** — CodeRabbit / cubic / Gitar / Socket Security / Gemini Code Assist が各 PR にコメント。
- **Dependabot** — npm / GitHub Actions の週次依存更新 (minor/patch をグループ化)。

## ライセンス

MIT (upstream と同じ)。画像アセットも MIT。

フォークは Marcel Dierkes 氏の copyright を残しつつ独自の attribution を追加 (アプリ内 *About* + `Credits.rtf` を参照)。upstream の依頼 — 同じ名前 / アイコンで fork を再配布しないこと — を尊重し、本フォークは表示名 **KeepingYouAwake (Amphetamine)** + 橙色のカップアイコンで配布。

## 旧 macOS サポート

upstream と同じ:
- [Version 1.6.2](https://github.com/newmarcel/KeepingYouAwake/releases/tag/1.6.2) が macOS Sierra (10.12) 対応の最終版。
- [Version 1.5.2](https://github.com/newmarcel/KeepingYouAwake/releases/tag/1.5.2) が macOS Yosemite (10.10) / El Capitan (10.11) 対応の最終版。
