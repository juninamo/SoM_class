# セットアップガイド：シングルセル解析環境の構築

このガイドでは、シングルセル解析ワークショップに必要な環境を構築する手順を説明します。**macOS** と **Windows** の両方に対応しています。

## 1. R と RStudio のインストール

### macOS の場合
1.  **Rのダウンロード**: [cloud.r-project.org](https://cloud.r-project.org/bin/macosx/) にアクセスし、最新のmacOS版インストーラをダウンロードします（Apple Silicon/M1/M2/M3 か Intel かを確認してください）。
2.  **RStudio Desktopのダウンロード**: [posit.co/download/rstudio-desktop/](https://posit.co/download/rstudio-desktop/) にアクセスし、無料版（Free version）をインストールします。

### Windows の場合
1.  **Rのダウンロード**: [cloud.r-project.org](https://cloud.r-project.org/bin/windows/base/) にアクセスし、最新のWindows版をダウンロードします。
2.  **RStudio Desktopのダウンロード**: [posit.co/download/rstudio-desktop/](https://posit.co/download/rstudio-desktop/) にアクセスし、無料版（Free version）をインストールします。
3.  **Rtoolsのインストール**: **(Windowsでは必須)**
    -   Symphonyなどの発展的なパッケージをGitHubからインストールするためにRtoolsが必要です。
    -   [cloud.r-project.org](https://cloud.r-project.org/bin/windows/Rtools/) から、自身のRのバージョンに合わせたRtools（例：R 4.4.xならRtools44）をダウンロードしてインストールしてください。

## 2. 必要なRパッケージのインストール

RStudioを開き、画面下部の「Console」タブに以下のコマンドを入力して実行してください。

### A. 基本的なBioconductorパッケージ
```r
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install(c("BiocStyle", "glmGamPoi", "limma"))
```

### B. CRANパッケージ (Seurat, Harmonyなど)
```r
install.packages(c("Seurat", "harmony", "patchwork", "ggplot2", "dplyr", "remotes", "class"))
```

### C. 発展的なマッピング用パッケージ (Symphony & StabMap)
これらのパッケージはワークショップのPart 2で使用します。

**Symphony:**
```r
remotes::install_github("immunogenomics/symphony")
```

**StabMap:**
```r
BiocManager::install("StabMap")
```

## 3. データの準備

### A. データのダウンロード
本講義では **GSE278962** (JIA Synovial CITE-seq) のデータを使用します。
1.  講義資料またはGEOからデータをダウンロードしてください。
2.  以下のファイル（またはそれに相当するオブジェクト）があることを確認してください：
    -   `syno.rna.jia.rds` (ベースとなるデータセット)
    -   `syno.rna_Fan.rds` (Part 2で使用する参照データセット)

### B. フォルダ構成の整理
プロジェクト用のフォルダ（例：`SingleCellWorkshop`）を作成し、データファイルを `data/` フォルダの中に入れてください。

```
SingleCellWorkshop/
├── data/
│   ├── syno.rna.jia.rds
│   └── syno.rna_Fan.rds
├── single_cell_analysis.Rmd       (Part 1)
└── single_cell_analysis_part2.Rmd (Part 2)
```

## 4. インストールの確認

以下のスクリプトをRで実行して、エラーが出ないか確認してください。

```r
library(Seurat)
library(harmony)
library(symphony)
library(StabMap)

print("All packages loaded successfully!")
```

"All packages loaded successfully!" と表示されれば、準備完了です！
