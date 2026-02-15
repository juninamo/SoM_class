# =============================================================================
# Seurat Viewer Shiny App
# Seurat objectのRDSファイルを読み込み、遺伝子発現を可視化する
# =============================================================================

library(shiny)
library(bslib)
library(Seurat)
library(ggplot2)
library(DT)

# --- アプリのディレクトリ内のRDSファイルを検出 ---
app_dir <- dirname(sys.frame(1)$ofile %||% ".")
if (app_dir == ".") app_dir <- getwd()
rds_files <- list.files(app_dir, pattern = "\\.rds$", ignore.case = TRUE)

# --- 外部データベースURL生成ヘルパー ---
ncbi_gene_url <- function(gene_name) {
  paste0("https://www.ncbi.nlm.nih.gov/gene/?term=", gene_name)
}
immunexut_url <- function(gene_name) {
  paste0("https://www.immunexut.org/eqtlGenes?gene_symbol=", gene_name)
}
ampra2_url <- function(gene_name) {
  paste0("https://immunogenomics.io/ampra2/app/?ds=fibroblast&gene=",gene_name,"&groupby=none")
}

# =============================================================================
# 翻訳辞書
# =============================================================================
i18n <- list(
  ja = list(
    # サイドバー
    data_load       = "\U0001F4C2 データ読み込み",
    rds_file        = "RDSファイル",
    load_btn        = "読み込む",
    vis_settings    = "\U0001F52C 可視化設定",
    gene_name       = "遺伝子名",
    gene_placeholder = "ファイルを読み込んでください",
    group_var       = "グループ変数",
    plot_settings   = "\U0001F3A8 プロット設定",
    pt_size         = "点のサイズ",
    plot_height     = "プロットの高さ (px)",

    # DEG
    deg_settings      = "DEG解析設定",
    deg_group_var     = "グループ変数",
    deg_cat_prefix    = "[カテゴリ] ",
    deg_num_prefix    = "[数値] ",
    deg_percentile    = "Top / Bottom パーセンタイル (%)",
    deg_group1        = "Group 1 (テスト群)",
    deg_group2        = "Group 2 (コントロール群)",
    deg_all_others    = "その他全て (All others)",
    deg_logfc         = "logFC閾値",
    deg_pval          = "p値閾値",
    deg_run           = "DEG解析を実行",
    deg_total_cells   = "全細胞数: %s",
    deg_top_cells     = "Top %d%%: %s 細胞",
    deg_bottom_cells  = "Bottom %d%%: %s 細胞",

    # 通知
    notify_loading      = "データを読み込み中...",
    notify_not_seurat   = "選択されたファイルはSeuratオブジェクトではありません。",
    notify_no_umap      = "注意: UMAPが計算されていません。UMAP表示は利用できません。",
    notify_load_done    = "✅ 読み込み完了: %s 細胞 × %s 遺伝子",
    notify_error        = "エラー: ",
    notify_deg_running  = "DEG解析を実行中...",
    notify_deg_same     = "Group 1とGroup 2は異なるグループを選択してください。",
    notify_deg_done     = "✅ DEG解析完了: %d Up, %d Down",

    # プレースホルダ
    placeholder_load  = "\U0001F4C2 RDSファイルを選択して「読み込む」ボタンを押してください",
    placeholder_deg   = "上のパネルでグループを設定し「DEG解析を実行」ボタンを押してください",
    no_umap_title     = "⚠️ このSeuratオブジェクトにはUMAP reductionが含まれていません",
    no_umap_msg       = "先にRunUMAP()を実行して保存し直してください。"
  ),

  en = list(
    # Sidebar
    data_load       = "\U0001F4C2 Load Data",
    rds_file        = "RDS File",
    load_btn        = "Load",
    vis_settings    = "\U0001F52C Visualization",
    gene_name       = "Gene",
    gene_placeholder = "Load an RDS file first",
    group_var       = "Group Variable",
    plot_settings   = "\U0001F3A8 Plot Settings",
    pt_size         = "Point Size",
    plot_height     = "Plot Height (px)",

    # DEG
    deg_settings      = "DEG Analysis Settings",
    deg_group_var     = "Group Variable",
    deg_cat_prefix    = "[Category] ",
    deg_num_prefix    = "[Numeric] ",
    deg_percentile    = "Top / Bottom Percentile (%)",
    deg_group1        = "Group 1 (Test)",
    deg_group2        = "Group 2 (Control)",
    deg_all_others    = "All others",
    deg_logfc         = "logFC Threshold",
    deg_pval          = "p-value Threshold",
    deg_run           = "Run DEG Analysis",
    deg_total_cells   = "Total cells: %s",
    deg_top_cells     = "Top %d%%: %s cells",
    deg_bottom_cells  = "Bottom %d%%: %s cells",

    # Notifications
    notify_loading      = "Loading data...",
    notify_not_seurat   = "The selected file is not a Seurat object.",
    notify_no_umap      = "Note: No UMAP reduction found. UMAP plots are unavailable.",
    notify_load_done    = "✅ Loaded: %s cells × %s genes",
    notify_error        = "Error: ",
    notify_deg_running  = "Running DEG analysis...",
    notify_deg_same     = "Group 1 and Group 2 must be different.",
    notify_deg_done     = "✅ DEG complete: %d Up, %d Down",

    # Placeholders
    placeholder_load  = "\U0001F4C2 Select an RDS file and click 'Load'",
    placeholder_deg   = "Configure groups above and click 'Run DEG Analysis'",
    no_umap_title     = "⚠️ This Seurat object does not contain a UMAP reduction",
    no_umap_msg       = "Run RunUMAP() first and re-save the object."
  )
)

# =============================================================================
# UI
# =============================================================================
ui <- page_sidebar(
  title = "Seurat Viewer",
  theme = bs_theme(
    version = 5,
    bootswatch = "darkly",
    primary = "#6ea8fe",
    "navbar-bg" = "#1a1d23"
  ),

  # --- サイドバー ---
  sidebar = sidebar(
    width = 320,

    # ダーク/ブライトモード切替
    input_dark_mode(id = "dark_mode", mode = "dark"),

    # 言語切替
    radioButtons("lang", NULL,
      choices = c("\U0001F1EF\U0001F1F5 日本語" = "ja", "\U0001F1EC\U0001F1E7 English" = "en"),
      selected = "ja", inline = TRUE),

    hr(),

    # 動的サイドバーコンテンツ
    uiOutput("sidebar_content_ui")
  ),

  # --- メインパネル ---
  navset_card_tab(
    id = "main_tabs",

    nav_panel(
      title = "\U0001F3BB Violin",
      value = "violin",
      card_body(
        class = "p-2",
        uiOutput("violin_ui")
      )
    ),

    nav_panel(
      title = "\U0001F5FA\uFE0F Feature UMAP",
      value = "feature_umap",
      card_body(
        class = "p-2",
        uiOutput("feature_umap_ui")
      )
    ),

    nav_panel(
      title = "\U0001F3F7\uFE0F Group UMAP",
      value = "group_umap",
      card_body(
        class = "p-2",
        uiOutput("group_umap_ui")
      )
    ),

    nav_panel(
      title = "\U0001F4CA DEG",
      value = "deg",
      card_body(
        class = "p-2",
        uiOutput("deg_panel_ui")
      )
    )
  )
)

# =============================================================================
# Server
# =============================================================================
server <- function(input, output, session) {

  # --- 翻訳ヘルパー ---
  t <- function(key) {
    lang <- input$lang %||% "ja"
    i18n[[lang]][[key]] %||% key
  }

  # --- テーマ切替をリアクティブに反映 ---
  observe({
    is_dark <- input$dark_mode == "dark"
    if (is_dark) {
      session$setCurrentTheme(
        bs_theme(version = 5, bootswatch = "darkly", primary = "#6ea8fe")
      )
    } else {
      session$setCurrentTheme(
        bs_theme(version = 5, bootswatch = "flatly", primary = "#2c7be5")
      )
    }
  })

  # --- プロットテーマをモードに応じて切替 ---
  plot_theme <- reactive({
    is_dark <- isTRUE(input$dark_mode == "dark")
    if (is_dark) {
      list(
        bg = "#2b3035",
        fg = "#dee2e6",
        fg2 = "#adb5bd",
        accent = "#8ab4f8",
        theme = theme(
          plot.background = element_rect(fill = "#2b3035", color = NA),
          panel.background = element_rect(fill = "#2b3035", color = NA),
          text = element_text(color = "#dee2e6"),
          axis.text = element_text(color = "#adb5bd"),
          axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
          legend.position = "none",
          plot.title = element_text(size = 16, face = "bold", color = "#8ab4f8")
        ),
        theme_legend = theme(
          plot.background = element_rect(fill = "#2b3035", color = NA),
          panel.background = element_rect(fill = "#2b3035", color = NA),
          text = element_text(color = "#dee2e6"),
          axis.text = element_text(color = "#adb5bd"),
          legend.text = element_text(color = "#dee2e6"),
          plot.title = element_text(size = 16, face = "bold", color = "#8ab4f8")
        )
      )
    } else {
      list(
        bg = "#ffffff",
        fg = "#212529",
        fg2 = "#495057",
        accent = "#2c7be5",
        theme = theme(
          plot.background = element_rect(fill = "#ffffff", color = NA),
          panel.background = element_rect(fill = "#ffffff", color = NA),
          text = element_text(color = "#212529"),
          axis.text = element_text(color = "#495057"),
          axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
          legend.position = "none",
          plot.title = element_text(size = 16, face = "bold", color = "#2c7be5")
        ),
        theme_legend = theme(
          plot.background = element_rect(fill = "#ffffff", color = NA),
          panel.background = element_rect(fill = "#ffffff", color = NA),
          text = element_text(color = "#212529"),
          axis.text = element_text(color = "#495057"),
          legend.text = element_text(color = "#212529"),
          plot.title = element_text(size = 16, face = "bold", color = "#2c7be5")
        )
      )
    }
  })

  # --- リアクティブ値 ---
  seurat_obj <- reactiveVal(NULL)
  data_loaded <- reactiveVal(FALSE)
  deg_results <- reactiveVal(NULL)
  meta_col_types <- reactiveVal(list(cat = character(0), num = character(0)))
  deg_title_label <- reactiveVal("")

  # ==========================================================================
  # 動的サイドバー
  # ==========================================================================
  output$sidebar_content_ui <- renderUI({
    # input$langへの依存で言語切替時に再描画
    lang <- input$lang

    tagList(
      h5(t("data_load"), class = "text-primary mb-2"),

      selectInput(
        "rds_file", t("rds_file"),
        choices = rds_files,
        selected = rds_files[1]
      ),
      actionButton(
        "load_btn", t("load_btn"),
        class = "btn-primary w-100 mb-3",
        icon = icon("upload")
      ),

      hr(),

      h5(t("vis_settings"), class = "text-primary mb-2"),

      selectizeInput(
        "gene", t("gene_name"),
        choices = NULL,
        options = list(
          placeholder = t("gene_placeholder"),
          maxOptions = 50
        )
      ),

      # 外部データベースリンク
      uiOutput("external_links_ui"),

      selectInput(
        "group_var", t("group_var"),
        choices = NULL
      ),

      hr(),

      h5(t("plot_settings"), class = "text-primary mb-2"),

      sliderInput("pt_size", t("pt_size"), min = 0, max = 2, value = 0.3, step = 0.1),
      sliderInput("plot_height", t("plot_height"), min = 400, max = 1200, value = 600, step = 50)
    )
  })

  # --- 外部データベースリンク ---
  output$external_links_ui <- renderUI({
    req(input$gene)
    gene <- input$gene
    tagList(
      div(
        class = "d-grid gap-1 mb-2",
        tags$a(
          href = ncbi_gene_url(gene), target = "_blank",
          class = "btn btn-outline-info btn-sm",
          icon("dna"), paste0(" ", gene, " — NCBI Gene")
        ),
        tags$a(
          href = immunexut_url(gene), target = "_blank",
          class = "btn btn-outline-success btn-sm",
          icon("microscope"), paste0(" ", gene, " — ImmuNexUT")
        ),
        tags$a(
          href = ampra2_url(gene), target = "_blank",
          class = "btn btn-outline-warning btn-sm",
          icon("bone"), paste0(" ", gene, " — AMP RA2")
        )
      )
    )
  })

  # ==========================================================================
  # 言語切替時にすでに読込済みデータの選択肢を維持
  # ==========================================================================
  observeEvent(input$lang, {
    if (data_loaded()) {
      obj <- seurat_obj()
      meta <- obj@meta.data
      col_types <- meta_col_types()
      cat_cols <- col_types$cat
      num_cols <- col_types$num

      # 遺伝子リスト: 現在選択中を維持
      current_gene <- input$gene
      genes <- sort(rownames(obj))
      updateSelectizeInput(session, "gene",
                           choices = genes,
                           selected = current_gene,
                           server = TRUE)

      # グループ変数: 現在の選択を維持
      current_group <- input$group_var
      updateSelectInput(session, "group_var",
                        choices = cat_cols,
                        selected = current_group)

      # DEGグループ変数: ラベルを再生成
      current_deg_var <- input$deg_group_var
      deg_choices <- c(
        setNames(cat_cols, paste0(t("deg_cat_prefix"), cat_cols)),
        setNames(num_cols, paste0(t("deg_num_prefix"), num_cols))
      )
      updateSelectInput(session, "deg_group_var",
                        choices = deg_choices,
                        selected = current_deg_var)
    }
  }, ignoreInit = TRUE)

  # ==========================================================================
  # RDSファイル読み込み
  # ==========================================================================
  observeEvent(input$load_btn, {
    req(input$rds_file)

    showNotification(t("notify_loading"), type = "message", id = "loading")

    tryCatch({
      file_path <- file.path(app_dir, input$rds_file)
      obj <- readRDS(file_path)

      # Seuratオブジェクトか確認
      if (!inherits(obj, "Seurat")) {
        showNotification(t("notify_not_seurat"),
                         type = "error", id = "loading")
        return()
      }

      seurat_obj(obj)
      data_loaded(TRUE)
      deg_results(NULL)

      # 遺伝子リストを更新
      genes <- sort(rownames(obj))
      updateSelectizeInput(session, "gene",
                           choices = genes,
                           selected = genes[1],
                           server = TRUE)

      # meta.dataの列を分類
      meta <- obj@meta.data
      cat_cols <- names(meta)[sapply(meta, function(x) {
        is.factor(x) || is.character(x) || (is.numeric(x) && length(unique(x)) <= 50)
      })]
      num_cols <- names(meta)[sapply(meta, function(x) {
        is.numeric(x) && length(unique(x)) > 50
      })]
      meta_col_types(list(cat = cat_cols, num = num_cols))

      # seurat_clustersを優先的にデフォルトにする
      default_group <- if ("seurat_clusters" %in% cat_cols) {
        "seurat_clusters"
      } else {
        cat_cols[1]
      }

      updateSelectInput(session, "group_var",
                        choices = cat_cols,
                        selected = default_group)

      # DEG用のグループ変数: カテゴリカル + 数値を表示
      deg_choices <- c(
        setNames(cat_cols, paste0(t("deg_cat_prefix"), cat_cols)),
        setNames(num_cols, paste0(t("deg_num_prefix"), num_cols))
      )
      updateSelectInput(session, "deg_group_var",
                        choices = deg_choices,
                        selected = default_group)

      # UMAP存在チェック
      has_umap <- "umap" %in% names(obj@reductions)
      if (!has_umap) {
        showNotification(
          t("notify_no_umap"),
          type = "warning", duration = 8
        )
      }

      n_cells <- ncol(obj)
      n_genes <- nrow(obj)
      showNotification(
        sprintf(t("notify_load_done"),
                format(n_cells, big.mark = ","),
                format(n_genes, big.mark = ",")),
        type = "message", id = "loading", duration = 5
      )

    }, error = function(e) {
      showNotification(paste(t("notify_error"), e$message), type = "error", id = "loading")
    })
  })

  # ==========================================================================
  # DEG解析パネル UI（動的・言語対応）
  # ==========================================================================
  output$deg_panel_ui <- renderUI({
    lang <- input$lang  # 言語切替で再描画

    # DEGグループ変数の選択肢を直接生成
    col_types <- meta_col_types()
    cat_cols <- col_types$cat
    num_cols <- col_types$num
    deg_choices <- NULL
    deg_selected <- NULL
    if (length(cat_cols) > 0 || length(num_cols) > 0) {
      deg_choices <- c(
        setNames(cat_cols, paste0(t("deg_cat_prefix"), cat_cols)),
        setNames(num_cols, paste0(t("deg_num_prefix"), num_cols))
      )
      # 現在の選択を維持
      current <- isolate(input$deg_group_var)
      deg_selected <- if (!is.null(current) && current %in% c(cat_cols, num_cols)) {
        current
      } else if ("seurat_clusters" %in% cat_cols) {
        "seurat_clusters"
      } else if (length(cat_cols) > 0) {
        cat_cols[1]
      } else {
        num_cols[1]
      }
    }

    tagList(
      # DEG設定パネル
      div(
        class = "card mb-3",
        div(
          class = "card-body",
          h6(t("deg_settings"), class = "card-title text-primary"),
          fluidRow(
            column(12,
              selectInput("deg_group_var", t("deg_group_var"),
                          choices = deg_choices,
                          selected = deg_selected)
            )
          ),
          # カテゴリカル/数値で動的に切り替わるUI
          uiOutput("deg_group_settings_ui"),
          fluidRow(
            column(4,
              numericInput("deg_logfc", t("deg_logfc"), value = 0.25, min = 0, step = 0.1)
            ),
            column(4,
              numericInput("deg_pval", t("deg_pval"), value = 0.05, min = 0, max = 1, step = 0.01)
            ),
            column(4,
              div(style = "margin-top: 24px;",
                actionButton("run_deg", t("deg_run"),
                             class = "btn-primary w-100",
                             icon = icon("flask"))
              )
            )
          )
        )
      ),

      # 結果: Volcano + テーブル
      uiOutput("deg_results_ui")
    )
  })

  # --- DEGグループ変数の型判定 ---
  deg_var_is_numeric <- reactive({
    req(input$deg_group_var)
    col_types <- meta_col_types()
    input$deg_group_var %in% col_types$num
  })

  # --- DEGグループ設定UI（カテゴリ/数値で切替） ---
  output$deg_group_settings_ui <- renderUI({
    req(input$deg_group_var, seurat_obj())
    lang <- input$lang  # 言語依存

    if (deg_var_is_numeric()) {
      # 数値列の場合: パーセンタイルスライダー
      fluidRow(
        column(6,
          sliderInput("deg_percentile", t("deg_percentile"),
                      min = 5, max = 50, value = 25, step = 5,
                      post = "%")
        ),
        column(6,
          div(class = "mt-3",
            uiOutput("deg_numeric_info")
          )
        )
      )
    } else {
      # カテゴリカル列の場合: グループ選択
      obj <- seurat_obj()
      groups <- sort(unique(as.character(obj@meta.data[[input$deg_group_var]])))
      group2_choices <- c(
        setNames("__ALL_OTHERS__", t("deg_all_others")),
        setNames(groups, groups)
      )
      fluidRow(
        column(6,
          selectInput("deg_ident1", t("deg_group1"),
                      choices = groups, selected = groups[1])
        ),
        column(6,
          selectInput("deg_ident2", t("deg_group2"),
                      choices = group2_choices,
                      selected = if (length(groups) >= 2) groups[2] else "__ALL_OTHERS__")
        )
      )
    }
  })

  # --- 数値DEGの細胞数表示 ---
  output$deg_numeric_info <- renderUI({
    req(seurat_obj(), input$deg_group_var, deg_var_is_numeric(), input$deg_percentile)
    lang <- input$lang  # 言語依存
    obj <- seurat_obj()
    vals <- obj@meta.data[[input$deg_group_var]]
    n_total <- length(vals)
    pct <- input$deg_percentile / 100
    n_group <- floor(n_total * pct)
    div(
      class = "small",
      p(class = "mb-1", sprintf(t("deg_total_cells"), format(n_total, big.mark = ","))),
      p(class = "mb-1", sprintf(t("deg_top_cells"), input$deg_percentile, format(n_group, big.mark = ","))),
      p(class = "mb-0", sprintf(t("deg_bottom_cells"), input$deg_percentile, format(n_group, big.mark = ",")))
    )
  })

  # --- ヘルパー: UMAPの有無を確認 ---
  has_umap <- reactive({
    obj <- seurat_obj()
    if (is.null(obj)) return(FALSE)
    "umap" %in% names(obj@reductions)
  })

  # --- プレースホルダUI ---
  placeholder_ui <- function() {
    div(
      class = "text-center text-muted py-5",
      h4(t("placeholder_load"))
    )
  }

  no_umap_ui <- function() {
    div(
      class = "text-center text-warning py-5",
      h4(t("no_umap_title")),
      p(t("no_umap_msg"))
    )
  }

  # ==========================================================================
  # Violin Plot
  # ==========================================================================
  output$violin_ui <- renderUI({
    if (!data_loaded()) return(placeholder_ui())
    plotOutput("violin_plot", height = paste0(input$plot_height, "px"))
  })

  output$violin_plot <- renderPlot({
    req(seurat_obj(), input$gene, input$group_var)
    obj <- seurat_obj()
    pt <- plot_theme()
    Idents(obj) <- obj@meta.data[[input$group_var]]
    VlnPlot(obj, features = input$gene, pt.size = input$pt_size) + pt$theme
  }, bg = "transparent")

  # ==========================================================================
  # Feature UMAP
  # ==========================================================================
  output$feature_umap_ui <- renderUI({
    if (!data_loaded()) return(placeholder_ui())
    if (!has_umap()) return(no_umap_ui())
    plotOutput("feature_umap_plot", height = paste0(input$plot_height, "px"))
  })

  output$feature_umap_plot <- renderPlot({
    req(seurat_obj(), input$gene, has_umap())
    obj <- seurat_obj()
    pt <- plot_theme()
    FeaturePlot(obj, features = input$gene, pt.size = input$pt_size) + pt$theme_legend
  }, bg = "transparent")

  # ==========================================================================
  # Group UMAP
  # ==========================================================================
  output$group_umap_ui <- renderUI({
    if (!data_loaded()) return(placeholder_ui())
    if (!has_umap()) return(no_umap_ui())
    plotOutput("group_umap_plot", height = paste0(input$plot_height, "px"))
  })

  output$group_umap_plot <- renderPlot({
    req(seurat_obj(), input$group_var, has_umap())
    obj <- seurat_obj()
    pt <- plot_theme()
    DimPlot(obj, reduction = "umap", group.by = input$group_var,
            label = TRUE, pt.size = input$pt_size) + pt$theme_legend
  }, bg = "transparent")

  # ==========================================================================
  # DEG解析
  # ==========================================================================
  observeEvent(input$run_deg, {
    req(seurat_obj(), input$deg_group_var)

    showNotification(t("notify_deg_running"), type = "message", id = "deg_run")

    tryCatch({
      obj <- seurat_obj()

      if (deg_var_is_numeric()) {
        # --- 数値列: Top X% vs Bottom X% ---
        req(input$deg_percentile)
        vals <- obj@meta.data[[input$deg_group_var]]
        pct <- input$deg_percentile / 100
        top_threshold <- quantile(vals, 1 - pct, na.rm = TRUE)
        bottom_threshold <- quantile(vals, pct, na.rm = TRUE)

        label_col <- paste0("__deg_group_", input$deg_group_var)
        obj@meta.data[[label_col]] <- ifelse(
          vals >= top_threshold, paste0("Top ", input$deg_percentile, "%"),
          ifelse(vals <= bottom_threshold, paste0("Bottom ", input$deg_percentile, "%"),
                 "Middle")
        )
        Idents(obj) <- obj@meta.data[[label_col]]

        ident1_label <- paste0("Top ", input$deg_percentile, "%")
        ident2_label <- paste0("Bottom ", input$deg_percentile, "%")
        deg_title_label(paste0(input$deg_group_var, ": ", ident1_label, " vs ", ident2_label))

        markers <- FindMarkers(obj,
                               ident.1 = ident1_label,
                               ident.2 = ident2_label,
                               logfc.threshold = 0,
                               min.pct = 0.1)
      } else {
        # --- カテゴリカル列 ---
        req(input$deg_ident1, input$deg_ident2)

        if (input$deg_ident1 == input$deg_ident2) {
          showNotification(t("notify_deg_same"), type = "error")
          return()
        }

        Idents(obj) <- obj@meta.data[[input$deg_group_var]]
        ident2_val <- if (input$deg_ident2 == "__ALL_OTHERS__") NULL else input$deg_ident2
        ident2_display <- if (input$deg_ident2 == "__ALL_OTHERS__") "All others" else input$deg_ident2
        deg_title_label(paste0(input$deg_ident1, " vs ", ident2_display))

        markers <- FindMarkers(obj,
                               ident.1 = input$deg_ident1,
                               ident.2 = ident2_val,
                               logfc.threshold = 0,
                               min.pct = 0.1)
      }

      markers$gene <- rownames(markers)
      markers$neg_log10_pval <- -log10(markers$p_val_adj + 1e-300)
      markers$significance <- ifelse(
        abs(markers$avg_log2FC) >= input$deg_logfc & markers$p_val_adj < input$deg_pval,
        ifelse(markers$avg_log2FC > 0, "Up", "Down"),
        "NS"
      )

      deg_results(markers)

      n_up <- sum(markers$significance == "Up")
      n_down <- sum(markers$significance == "Down")
      showNotification(
        sprintf(t("notify_deg_done"),  n_up, n_down),
        type = "message", id = "deg_run", duration = 5
      )

    }, error = function(e) {
      showNotification(paste(t("notify_error"), e$message), type = "error", id = "deg_run")
    })
  })

  # --- DEG結果UI ---
  output$deg_results_ui <- renderUI({
    res <- deg_results()
    if (is.null(res)) {
      return(div(
        class = "text-center text-muted py-4",
        h5(t("placeholder_deg"))
      ))
    }

    tagList(
      # Volcano Plot
      div(class = "mb-3",
        plotOutput("volcano_plot", height = "500px")
      ),
      # DEGテーブル
      div(
        DTOutput("deg_table")
      )
    )
  })

  # --- Volcano Plot ---
  output$volcano_plot <- renderPlot({
    req(deg_results())
    res <- deg_results()
    pt <- plot_theme()

    colors <- c("Up" = "#e74c3c", "Down" = "#3498db", "NS" = "#95a5a6")

    # ラベル用: top 10遺伝子
    top_genes <- res[res$significance != "NS", ]
    top_genes <- top_genes[order(top_genes$p_val_adj), ]
    top_genes <- head(top_genes, 10)

    p <- ggplot(res, aes(x = avg_log2FC, y = neg_log10_pval, color = significance)) +
      geom_point(alpha = 0.6, size = 1.5) +
      scale_color_manual(values = colors) +
      geom_vline(xintercept = c(-input$deg_logfc, input$deg_logfc),
                 linetype = "dashed", color = pt$fg2, linewidth = 0.5) +
      geom_hline(yintercept = -log10(input$deg_pval),
                 linetype = "dashed", color = pt$fg2, linewidth = 0.5) +
      labs(
        title = paste0("Volcano Plot: ", deg_title_label()),
        x = "avg_log2FC",
        y = "-log10(p_val_adj)",
        color = ""
      ) +
      theme_minimal(base_size = 14) +
      theme(
        plot.background = element_rect(fill = pt$bg, color = NA),
        panel.background = element_rect(fill = pt$bg, color = NA),
        panel.grid.major = element_line(color = paste0(pt$fg2, "40")),
        panel.grid.minor = element_blank(),
        text = element_text(color = pt$fg),
        axis.text = element_text(color = pt$fg2),
        legend.text = element_text(color = pt$fg),
        plot.title = element_text(size = 16, face = "bold", color = pt$accent)
      )

    # トップ遺伝子ラベル
    if (nrow(top_genes) > 0) {
      p <- p + ggrepel::geom_text_repel(
        data = top_genes,
        aes(label = gene),
        color = pt$fg,
        size = 3.5,
        max.overlaps = 20,
        segment.color = pt$fg2
      )
    }

    p
  }, bg = "transparent")

  # --- DEGテーブル ---
  output$deg_table <- renderDT({
    req(deg_results())
    res <- deg_results()

    # 有意な遺伝子のみフィルタ（全体も閲覧可能にするが初期表示は有意なもの）
    display_cols <- c("gene", "avg_log2FC", "pct.1", "pct.2", "p_val_adj", "significance")
    df <- res[, display_cols, drop = FALSE]

    # 外部データベースリンクを追加
    df$Links <- paste0(
      '<a href="', sapply(df$gene, ncbi_gene_url),
      '" target="_blank" class="btn btn-outline-info btn-sm btn-xs me-1" title="NCBI Gene">',
      'NCBI</a>',
      '<a href="', sapply(df$gene, immunexut_url),
      '" target="_blank" class="btn btn-outline-success btn-sm btn-xs me-1" title="ImmuNexUT">',
      'ImmuNexUT</a>',
      '<a href="', sapply(df$gene, ampra2_url),
      '" target="_blank" class="btn btn-outline-warning btn-sm btn-xs" title="AMP RA2">',
      'AMP RA2</a>'
    )

    # 数値の丸め（p_val_adjは数値のまま渡し、JSで表示時に指数表記にする）
    df$avg_log2FC <- round(df$avg_log2FC, 4)
    df$pct.1 <- round(df$pct.1, 3)
    df$pct.2 <- round(df$pct.2, 3)

    datatable(
      df,
      escape = FALSE,
      rownames = FALSE,
      filter = "top",
      options = list(
        pageLength = 20,
        order = list(list(4, "asc")),
        dom = "Blfrtip",
        scrollX = TRUE,
        columnDefs = list(
          list(
            targets = 4,
            render = DT::JS(
              "function(data, type, row, meta) {",
              "  if (type === 'display' || type === 'filter') {",
              "    if (data === null) return '';",
              "    return Number(data).toExponential(2);",
              "  }",
              "  return data;",
              "}"
            )
          )
        )
      ),
      colnames = c("Gene", "avg_log2FC", "pct.1", "pct.2", "p_val_adj", "Status", "External DB")
    )
  })
}

# --- アプリ実行 ---
shinyApp(ui = ui, server = server)
