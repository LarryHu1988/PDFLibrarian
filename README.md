# 📚 PDF Librarian

<p align="center">
  <img src="docs/assets/PDFLibrarian-logo-1024.png" alt="PDF Librarian Logo" width="160" />
</p>

<p align="center">
  A macOS app for cleaning up, standardizing, and renaming book and academic paper PDFs.
</p>

<p align="center">
  <a href="https://github.com/LarryHu1988/PDFLibrarian/releases">
    <img src="https://img.shields.io/github/v/release/LarryHu1988/PDFLibrarian?display_name=tag&sort=semver" alt="Release">
  </a>
  <img src="https://img.shields.io/badge/macOS-13.0%2B-black" alt="macOS 13+">
  <img src="https://img.shields.io/badge/Swift-5.10-orange" alt="Swift 5.10">
  <img src="https://img.shields.io/badge/status-stable-2ea44f" alt="Stable">
</p>

<p align="center">
  <a href="#-中文">中文</a> •
  <a href="#-english">English</a> •
  <a href="https://github.com/LarryHu1988/PDFLibrarian/releases">Download</a>
</p>

## ✨ Highlights

- 🔎 Search metadata from filename hints and extracted PDF content
- 🌐 Merge results from `Google Books`, `Open Library`, `Douban`, and `Library of Congress`
- 🧩 Deduplicate candidates by `ISBN -> DOI -> title + author`
- 🏷️ Review and edit Dublin Core fields before writing
- ✅ Write metadata using the final confirmed values
- 📝 Generate rename suggestions from the latest written metadata
- ✍️ Edit the final file name before rename
- 🌗 Support `Daylight / Moonlight` appearance modes
- 🌍 Support a multi-language UI

## 🚀 Download

- [Latest Release](https://github.com/LarryHu1988/PDFLibrarian/releases)
- Current official version: `V1.0.0`
- Release assets: `PDFLibrarian-1.0.0.dmg` and `PDFLibrarian-1.0.0.zip`

## 🧭 Workflow

1. Select a PDF file or folder
2. Search and merge metadata candidates
3. Review, edit, and confirm Dublin Core values
4. Confirm or edit the final file name and rename the PDF

## 🏷️ Default Dublin Core Fields

`dc:title`, `dc:creator`, `dc:publisher`, `dc:date`, `dc:language`, `dc:type`, `dc:format`, `dc:identifier`, `dc:subject`

## 🛠️ Build From Source

```bash
swift build
./scripts/package_app.sh
./scripts/build_release_assets.sh
```

Build artifacts are generated in `dist/`.

## 🇨🇳 中文

### 产品简介

PDF Librarian 是一款面向 macOS 的 PDF 元数据整理工具，适合书籍、论文和参考资料归档。

### 功能亮点

- 🔎 根据文件名和 PDF 内容提示检索元数据
- 🌐 聚合 `Google Books`、`Open Library`、`豆瓣网页搜索`、`Library of Congress`
- 🧩 按 `ISBN -> DOI -> 标题+作者` 去重并合并候选
- 🏷️ 写入前可手动编辑 Dublin Core 字段
- ✅ 按确认后的字段值写回 PDF 元数据
- 📝 基于最新写入的元数据生成建议文件名
- ✍️ 重命名时允许再次手动修改最终文件名
- 🌗 支持 `日光 / 月光` 外观
- 🌍 支持多语言界面

### 使用流程

1. 选择 PDF 文件或文件夹
2. 联网检索并合并候选元数据
3. 编辑并确认写入 Dublin Core 字段
4. 确认或修改最终文件名后执行重命名

### 默认写入字段

`dc:title`、`dc:creator`、`dc:publisher`、`dc:date`、`dc:language`、`dc:type`、`dc:format`、`dc:identifier`、`dc:subject`

### 从源码构建

```bash
swift build
./scripts/package_app.sh
./scripts/build_release_assets.sh
```

构建产物位于 `dist/`。

## 🇺🇸 English

### Overview

PDF Librarian is a macOS desktop app for cleaning up and standardizing metadata in book and academic paper PDFs.

### Key Features

- 🔎 Metadata lookup from filename and extracted PDF hints
- 🌐 Multi-source search across `Google Books`, `Open Library`, `Douban`, and `Library of Congress`
- 🧩 Deduplication and merge flow using `ISBN -> DOI -> title + author`
- 🏷️ Editable Dublin Core values before writing
- ✅ Metadata writing uses the final confirmed field values
- 📝 Rename suggestions are generated from the latest written metadata
- ✍️ Users can edit the final file name before rename
- 🌗 `Daylight / Moonlight` appearance modes
- 🌍 Multi-language UI

### Workflow

1. Select a PDF file or folder
2. Search and merge metadata candidates
3. Review, edit, and confirm Dublin Core values
4. Confirm or edit the final file name and rename the PDF

### Default Fields

`dc:title`, `dc:creator`, `dc:publisher`, `dc:date`, `dc:language`, `dc:type`, `dc:format`, `dc:identifier`, `dc:subject`
