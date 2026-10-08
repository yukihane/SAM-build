# SAM ビルド用リポジトリ

[SAM](https://sam.nlr.gov/) の公開ソースをビルドするため、必要な4リポジトリを Git submodule で管理します。

## ソース構成

すべての submodule は公式の [NatLabRockies](https://github.com/NatLabRockies) から取得し、安定版タグ `2026.7.3.r0.ssc.308` が指すコミットに固定しています。

| ディレクトリ | 公式リポジトリ | 役割 |
| --- | --- | --- |
| `SAM/` | [SAM](https://github.com/NatLabRockies/SAM) | デスクトップアプリケーション |
| `ssc/` | [ssc](https://github.com/NatLabRockies/ssc) | シミュレーションの計算モデル |
| `lk/` | [lk](https://github.com/NatLabRockies/lk) | 組み込みスクリプト言語 |
| `wex/` | [wex](https://github.com/NatLabRockies/wex) | GUI部品・表示ツール |

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

## ビルド環境

この構成で管理するのは SAM・SSC・LK・WEX のソースです。ビルドには、別途 wxWidgets、OR-Tools、コンパイラ、CMake などの準備が必要です。ビルド環境の構築とビルドの検証はまだ行っていません。
