# はじめてのシングルセル解析：Google Colab 実習ガイド

**JIA滑膜CITE-seqデータ — T細胞サブクラス解析 (Part 2)**

> 慶應義塾大学医学部 微生物学・免疫学教室 / 稲毛 純（Inamo Jun）

---

## 📁 ファイル構成

```
.
├── setup_colab_guide_jp.md            ← このファイル
├── single_cell_analysis_T_colab.ipynb ← 学生配布用 Colab ノートブック
└── setup_R_libs_for_students.ipynb    ← 【先生専用】R_libs.zip 作成用
```

---

## 全体フロー

```
【先生：1回のみ】                       【学生：毎セッション】
setup_R_libs_for_students.ipynb        single_cell_analysis_T_colab.ipynb
  ↓ セル1: Seurat 等インストール
  ↓ セル2: R_libs.zip をダウンロード
  ↓
  配布ファイル（2つ）
  ├── R_libs.zip                  →  アップロード → セル1: 展開・読込
  └── JIAsyno_CITEseq_T_share.rds →  アップロード → セル2: 読込
                                       ↓
                                       解析開始
```



---

## 🧑‍🏫 先生側：事前準備（1回のみ）

### 使用するノートブック
[`setup_R_libs_for_students.ipynb`](setup_R_libs_for_students.ipynb)

### 手順

#### 1. Colab を開いてカーネルを R に設定

1. [Google Colab](https://colab.research.google.com) を開く
2. `setup_R_libs_for_students.ipynb` をアップロード
3. メニュー「ランタイム」→「ランタイムのタイプを変更」→ **R** を選択 → 保存

#### 2. セル1：パッケージのインストール（40〜60分）

- `Seurat`, `BiocStyle`, `magrittr`, `patchwork`, `dplyr`, `ggplot2` を `/content/R_libs/` にインストール
- **すでにインストール済みの場合はスキップ可**

#### 3. セル2：R_libs.zip の作成・ダウンロード

- `/content/R_libs/` を zip 圧縮して、ローカル PC にダウンロード
- 実行すると `R_libs.zip` が自動でダウンロードされる

#### 4. 学生への配布ファイル

以下の **3ファイル** を学生に配布してください（メール・Google Drive・GitHub Releases など）。

現時点（2026年2月25日）：講義で使用するデータは学生に**事前**に[こちら](https://drive.google.com/drive/folders/1ZW-uxlEOZ7xWBXT1D6wTNbN6fYFvRMye?usp=sharing)よりダウンロードしてもらう。
→（**XX月XX日までに3つのファイル全てをダウンロードしてもらうことを学生に周知する**）

| ファイル名 | 内容 |
|---|---|
| `R_libs.zip` | 上で作成したRパッケージ群 |
| `JIAsyno_CITEseq_T_share.rds` | 解析用T細胞データ |
| `single_cell_analysis_T_colab.ipynb`| 学生配布用 Colab ノートブック |

---

## 🎓 学生側：解析の実行手順（毎回）

### 使用するノートブック
[`single_cell_analysis_T_colab.ipynb`](single_cell_analysis_T_colab.ipynb)

### ステップ①：ランタイムを R に設定（初回のみ）

1. ノートブックを Colab で開く（Google accountはkeio.jpで入る）
2. メニュー「ランタイム」→「ランタイムのタイプを変更」→ **R** を選択 → 保存

### ステップ②：2つのファイルをアップロード

Colab の左サイドバーにある 📁 ファイルアイコンをクリック →「**アップロード**」

| アップロードするファイル | 説明 |
|---|---|
| `R_libs.zip` | 先生から受け取ったもの |
| `JIAsyno_CITEseq_T_share.rds` | 先生から受け取ったもの |

> ⚠️ 両方のファイルが左のファイル一覧（`/content/` 下）に表示されるまで待ってください。

### ステップ③：セル1 を実行（約2〜3分）

`R_libs.zip` を展開して Seurat 等のパッケージを読み込みます。

```
✅ セットアップ完了！ Seurat バージョン: 5.4.0
```
と表示されたら成功です。

### ステップ④：セル2 を実行

`JIAsyno_CITEseq_T_share.rds` を読み込みます。

```
✅ データ読み込み完了！
```
と表示されたら解析開始です。

### ステップ⑤：解析を上から順に実行

| セル | 内容 |
|---|---|
| 高変動遺伝子の再選出 | T細胞内で重要な遺伝子を特定 |
| PCA | 主成分分析・エルボープロット |
| クラスタリング・UMAP | T細胞サブグループを可視化 |
| マーカー遺伝子の発現 | FeaturePlot / VlnPlot |
| **🎓 実習パート** | クラスターに細胞名を付ける（`?????` を書き換える） |
| resolution 比較 | 解像度を変えた実験（課題） |

---

## ❓ トラブルシューティング

| エラー | 対処 |
|---|---|
| `R_libs.zip が見つかりません` | ファイルのアップロードを確認。左のファイル一覧に表示されるまで待つ |
| `JIAsyno_CITEseq_T_share.rds が見つかりません` | 同上 |
| `library(Seurat)` でエラー | セル1 からやり直す。R_libs.zip が壊れている場合は先生に連絡 |
| セッションが切れた | 再接続後、ファイルを再アップロードしてセル1から実行 |

> ℹ️ Colab の無料セッションは **最長12時間** で切断されます。  
> セッションが切れると `/content/` の内容が消えるため、再接続後は **ファイルの再アップロード** が必要です。

---

## 📝 解析の概要

本実習は JIA（若年性特発性関節炎）滑膜の CITE-seq データから抽出した **T細胞集団のサブクラス解析** を行います。

### 解析パイプライン

```
T細胞サブセット (RDS)
  ↓ FindVariableFeatures   高変動遺伝子の再選出
  ↓ ScaleData + RunPCA     スケーリング・主成分分析
  ↓ FindNeighbors          近傍グラフ構築
  ↓ FindClusters           クラスタリング (resolution = 0.8)
  ↓ RunUMAP                次元削減・可視化
  ↓ FeaturePlot / VlnPlot  マーカー遺伝子の発現確認
  ↓ 【実習】RenameIdents   クラスター名の付与
```

### 主なマーカー遺伝子

| マーカー | 細胞種 |
|---|---|
| CD4 | ヘルパーT細胞 |
| CD8A | キラーT細胞 |
| CCR7 | ナイーブT細胞 |
| FOXP3 | 制御性T細胞 (Treg) |
| CXCL13 | Tfh / Tph |
| NCAM1 / FCGR3A | NK細胞 |
| TRDV2 / TRGV9 | γδ T細胞 |
| ZNF683 / KLRC2 | 組織常在性メモリーT細胞 (TRM) |

---

## 動作環境

| 項目 | 内容 |
|---|---|
| 実行環境 | Google Colab（R カーネル） |
| R バージョン | 4.x |
| 主要パッケージ | Seurat 5.x, BiocStyle, dplyr, ggplot2, patchwork |
| 必要メモリ | 約 8GB（Colab 無料版で概ね動作可能） |
