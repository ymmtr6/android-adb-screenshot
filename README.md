# android-screenshot

macOS から adb + scrcpy を使って Android 端末を操作し、スクリーンショットを取得するための最小ツール集です。

## セットアップ

1. Android 端末で「開発者向けオプション」→「USB デバッグ」を有効化
2. USB 接続後、端末の認証ダイアログで許可
3. 必要ツールの確認/インストール

```bash
scripts/setup.sh
scripts/setup.sh --install
```

## 使い方

### 端末操作 (scrcpy)

```bash
scripts/run_scrcpy.sh
```

複数端末がある場合:

```bash
adb devices -l
scripts/run_scrcpy.sh -s SERIAL
```

追加オプション例:

```bash
SCRCPY_ARGS="--turn-screen-off --show-touches" scripts/run_scrcpy.sh
```

### スクリーンショット

```bash
scripts/screenshot.sh
```

出力先やファイル名プレフィックスを変更:

```bash
scripts/screenshot.sh -o assets/screenshots -p demo
```

### カスタム操作: 右スワイプ + スクリーンショット

```bash
scripts/auto_swipe.sh
```

スワイプ距離を増やす場合:

```bash
SWIPE_START_PCT=90 SWIPE_END_PCT=10 scripts/auto_swipe.sh
```

スワイプの高さをランダムにする場合:

```bash
SWIPE_Y_MIN_PCT=35 SWIPE_Y_MAX_PCT=70 scripts/auto_swipe.sh
```

開始インデックスを指定する場合:

```bash
scripts/auto_swipe.sh -i 120
```

複数端末がある場合:

```bash
adb devices -l
scripts/auto_swipe.sh -s SERIAL
```

停止条件:
- スクリーンショットが2回連続で変化しない
- Ctrl+C

### 漫画部分のトリミング

ImageMagick が必要です。

```bash
brew install imagemagick
```

```bash
scripts/trim_manga.sh assets/screenshots
```

上/下のカット量を変更する場合:

```bash
scripts/trim_manga.sh -t 400 -b 420 assets/screenshots
```

出力先を変える場合:

```bash
scripts/trim_manga.sh -o assets/screenshots/trimmed assets/screenshots
```

元ファイルを残す場合:

```bash
scripts/trim_manga.sh -k assets/screenshots
```

### PNG から PDF を作成

ImageMagick が必要です。

```bash
scripts/pngs_to_pdf.sh assets/screenshots
```

出力先を指定する場合:

```bash
scripts/pngs_to_pdf.sh -o assets/screenshots/manga.pdf assets/screenshots
```

### 末尾3枚を削除

自然順で最後の3枚の PNG を削除します。

```bash
scripts/remove_last3.sh assets/screenshots
```

### 一括実行

`auto_swipe -> remove_last3 -> trim -> pngs_to_pdf` を順に実行します。

```bash
scripts/run_all.sh TITLE -s SERIAL
```

Slack 通知を使う場合:

1) `scripts/run_all.env.example` を `scripts/run_all.env` にコピー  
2) Webhook URL を設定

## トラブルシュート

- `adb devices` に `unauthorized` と出る: 端末側で接続許可を再確認
- 端末が見えない: USB ケーブル/ポート変更、USB デバッグの再有効化
