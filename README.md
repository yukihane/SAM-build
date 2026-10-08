# SAM ビルド用リポジトリ

[SAM](https://sam.nlr.gov/) の公開ソースをビルドするため、アプリケーションを構成する4リポジトリと wxWidgets を Git submodule で管理します。

## ソース構成

SAM・SSC・LK・WEX は公式の [NatLabRockies](https://github.com/NatLabRockies) から取得し、安定版タグ `2026.7.3.r0.ssc.308` が指すコミットに固定しています。wxWidgets は公式リポジトリのタグ `v3.2.8.1` が指すコミットに固定しています。

| ディレクトリ | 公式リポジトリ | 役割 |
| --- | --- | --- |
| `SAM/` | [SAM](https://github.com/NatLabRockies/SAM) | デスクトップアプリケーション |
| `ssc/` | [ssc](https://github.com/NatLabRockies/ssc) | シミュレーションの計算モデル |
| `lk/` | [lk](https://github.com/NatLabRockies/lk) | 組み込みスクリプト言語 |
| `wex/` | [wex](https://github.com/NatLabRockies/wex) | GUI部品・表示ツール |
| `wxWidgets/` | [wxWidgets](https://github.com/wxWidgets/wxWidgets) | GUIの基盤ライブラリ |

## ソースの取得

このリポジトリを clone した後、リポジトリ直下で実行します。

```powershell
git submodule update --init --recursive
```

初回の clone に `--recurse-submodules` を指定する方法もあります。

各 submodule のコミットは親リポジトリに記録されています。ブランチを追従する `git submodule update --remote` は使用せず、通常の `git submodule update --init --recursive` で固定されたソースを再現します。各 submodule が detached HEAD になるのは、この固定によるものです。

取得状態は次のコマンドで確認できます。

```powershell
git submodule status --recursive
```

## Windows用の依存ライブラリ

VS2022 の MSVC・MSBuild・Windows SDK が必要です。CMake は3.24以上を用意します。以下のコマンドはリポジトリ直下から PowerShell で実行します。スクリプト内部の保存先はスクリプトの場所を基準にするため、別の作業ディレクトリから実行しても同じ場所を使用します。

### wxWidgets のビルド

```powershell
git submodule update --init --recursive
.\scripts\Build-WxWidgets.ps1
```

VS2022 の `MSBuild.exe` を自動検出し、公式の `wx_vc17.sln` を Release/x64、Debug/x64 の順にビルドします。初期化時の `--recursive` は wxWidgets 内の依存 submodule にも必要です。

- ライブラリ: `wxWidgets/lib/vc_x64_lib/`
- ビルドログ: `logs/wxWidgets-Release-x64.log`、`logs/wxWidgets-Debug-x64.log`
- 再実行時は MSBuild の増分ビルドを使用します。

特定の構成だけビルドする場合は `-Configuration Release` または `-Configuration Debug` を指定します。並列数は `-MaxCpuCount 4` で指定でき、既定値も4です。

### OR-Tools の取得

```powershell
.\scripts\Get-OrTools.ps1
```

公式の VS2022/x64 用 OR-Tools 9.14.6206 を取得します。スクリプトは、最後に展開先の絶対パスを出力します。

- ZIP: `downloads/or-tools_x64_VisualStudio2022_cpp_v9.14.6206.zip`
- 展開先: `deps/or-tools_x64_VisualStudio2022_cpp_v9.14.6206/`
- ZIP の SHA-256 は、公式 GitHub リリースの配布物メタデータにある値で検証します。
- 取得済みの ZIP はハッシュが一致すれば再利用します。
- 展開先に完了マーカーと必要なファイルがあれば、再ダウンロード・再展開を省略します。
- ダウンロードと展開には一時ファイル・一時ディレクトリを使い、検証成功後に配置します。
- 展開先が既にあり、完了マーカーや必要なファイルが欠けている場合はエラーにします。そのディレクトリを別の場所へ移動してから再実行してください。

ZIP・展開済み配布物・ビルドログは親リポジトリの `.gitignore` で管理対象から除外します。wxWidgets の生成物は同 submodule の `.gitignore` に従います。

### 後続の SAM ビルドで使用するパス

```powershell
$env:WXMSW3 = (Resolve-Path .\wxWidgets).Path
$env:ORTOOLSDIR = & .\scripts\Get-OrTools.ps1
```

SAM 本体の統合 CMake 設定とビルドは、次の作業として用意します。
