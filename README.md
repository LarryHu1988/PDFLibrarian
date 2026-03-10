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
  <img src="https://img.shields.io/badge/License-Proprietary-6b7280" alt="License: Proprietary">
</p>

<p align="center">
  <a href="#overview">Overview</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#faq">FAQ</a> •
  <a href="#chinese">中文</a> •
  <a href="https://github.com/LarryHu1988/PDFLibrarian/releases">Download</a>
</p>

<p align="center">
  <a href="https://github.com/LarryHu1988/PDFLibrarian/releases/download/V1.0.0/PDFLibrarian-1.0.0.dmg">
    <img src="https://img.shields.io/badge/Download-DMG-2563eb?style=for-the-badge&logo=apple&logoColor=white" alt="Download DMG">
  </a>
  <a href="https://github.com/LarryHu1988/PDFLibrarian/releases/download/V1.0.0/PDFLibrarian-1.0.0.zip">
    <img src="https://img.shields.io/badge/Download-ZIP-0f766e?style=for-the-badge" alt="Download ZIP">
  </a>
  <a href="https://github.com/LarryHu1988/PDFLibrarian/releases/tag/V1.0.0">
    <img src="https://img.shields.io/badge/View-Release%20Notes-7c3aed?style=for-the-badge&logo=github&logoColor=white" alt="View Release Notes">
  </a>
</p>

<table>
  <tr>
    <td width="25%" align="center">
      <a href="#highlights"><strong>✨ Features</strong></a><br>
      Lookup, merge, write, rename
    </td>
    <td width="25%" align="center">
      <a href="#screenshots"><strong>🖼️ Screenshots</strong></a><br>
      English and Chinese UI
    </td>
    <td width="25%" align="center">
      <a href="#download"><strong>⬇️ Download</strong></a><br>
      DMG and ZIP assets
    </td>
    <td width="25%" align="center">
      <a href="#license"><strong>📄 License</strong></a><br>
      Proprietary release terms
    </td>
  </tr>
  <tr>
    <td width="25%" align="center">
      <a href="#faq"><strong>❓ FAQ</strong></a><br>
      Common workflow answers
    </td>
    <td width="25%" align="center">
      <a href="#workflow"><strong>🧭 Workflow</strong></a><br>
      4-step metadata flow
    </td>
    <td width="25%" align="center">
      <a href="#fields"><strong>🏷️ Fields</strong></a><br>
      Default Dublin Core set
    </td>
    <td width="25%" align="center">
      <a href="#chinese"><strong>🇨🇳 中文</strong></a><br>
      Chinese overview and FAQ
    </td>
  </tr>
</table>

<a id="overview"></a>
## ✨ Overview

PDF Librarian helps organize book and paper PDFs on macOS with a clear four-step workflow: select files, search metadata, confirm editable Dublin Core fields, and rename files using the latest written metadata.

<a id="highlights"></a>
## 🚀 Highlights

- 🔎 Search metadata from filename hints and extracted PDF content
- 🌐 Merge results from `Google Books`, `Open Library`, `Douban`, and `Library of Congress`
- 🧩 Deduplicate candidates by `ISBN -> DOI -> title + author`
- 🏷️ Review and edit Dublin Core fields before writing
- ✅ Write metadata using the final confirmed values
- 📝 Generate rename suggestions from the latest written metadata
- ✍️ Edit the final file name before rename
- 🌗 Support `Daylight / Moonlight` appearance modes
- 🌍 Support a multi-language UI

<a id="screenshots"></a>
## 🖼️ Screenshots

### 🇺🇸 English UI

<table>
  <tr>
    <td align="center"><strong>Daylight</strong></td>
    <td align="center"><strong>Moonlight</strong></td>
  </tr>
  <tr>
    <td><img src="docs/assets/pdflibrarian-en-light-full.png" alt="PDF Librarian English Daylight UI"></td>
    <td><img src="docs/assets/pdflibrarian-en-dark-full.png" alt="PDF Librarian English Moonlight UI"></td>
  </tr>
</table>

### 🇨🇳 Chinese UI

<table>
  <tr>
    <td align="center"><strong>Daylight</strong></td>
    <td align="center"><strong>Moonlight</strong></td>
  </tr>
  <tr>
    <td><img src="docs/assets/pdflibrarian-zh-Hans-light-full.png" alt="PDF Librarian Chinese Daylight UI"></td>
    <td><img src="docs/assets/pdflibrarian-zh-Hans-dark-full.png" alt="PDF Librarian Chinese Moonlight UI"></td>
  </tr>
</table>

## 📊 Feature Matrix

| Feature | Support | Notes |
| --- | --- | --- |
| Multi-source metadata lookup | ✅ | Queries `Google Books`, `Open Library`, `Douban`, and `Library of Congress` |
| Deduplication and merge flow | ✅ | Prioritizes `ISBN -> DOI -> title + author` |
| Editable Dublin Core fields | ✅ | Review and correct values before writing |
| Confirmed-value metadata write | ✅ | Uses the final edited values from step 3 |
| Rename from latest written metadata | ✅ | Keeps file names aligned with the newest metadata |
| Manual final file name edit | ✅ | Step 4 still allows a last manual adjustment |
| Daylight / Moonlight themes | ✅ | Designed for both bright and dark desktop setups |
| Chinese / English UI | ✅ | Suitable for local and global workflows |

<a id="faq"></a>
## ❓ FAQ

1. **Does the app upload PDFs?**  
   No. The app reads PDFs you explicitly select on your Mac and sends metadata hints such as title, author, ISBN, or DOI to public metadata sources when needed. It does not upload the full PDF file.

2. **Can I edit metadata before writing?**  
   Yes. Step 3 is an editable review step, and the app writes exactly the values you confirm there.

3. **Does rename use the latest written metadata?**  
   Yes. Rename suggestions are generated from the latest metadata written into the PDF, not from stale candidate values.

4. **Can I change the final file name manually?**  
   Yes. Step 4 allows manual edits before the rename is applied.

5. **What kind of PDFs is this app for?**  
   It is designed for book PDFs, academic papers, and reference documents that benefit from cleaner metadata and library-friendly file names.

<a id="download"></a>
## ⬇️ Download

- [Latest Release](https://github.com/LarryHu1988/PDFLibrarian/releases)
- Current official version: `V1.0.0`
- Release assets: `PDFLibrarian-1.0.0.dmg` and `PDFLibrarian-1.0.0.zip`

<a id="workflow"></a>
## 🧭 Workflow

1. Select a PDF file or folder
2. Search and merge metadata candidates
3. Review, edit, and confirm Dublin Core values
4. Confirm or edit the final file name and rename the PDF

<a id="fields"></a>
## 🏷️ Default Dublin Core Fields

`dc:title`, `dc:creator`, `dc:publisher`, `dc:date`, `dc:language`, `dc:type`, `dc:format`, `dc:identifier`, `dc:subject`

## 🛠️ Build From Source

```bash
swift build
./scripts/package_app.sh
./scripts/build_release_assets.sh
```

Build artifacts are generated in `dist/`.

<a id="license"></a>
## 📄 License

This repository is distributed under a proprietary, all-rights-reserved license. See [`LICENSE`](LICENSE).

<a id="chinese"></a>
## 🇨🇳 中文

### 🧾 产品简介

PDF Librarian 是一款面向 macOS 的 PDF 元数据整理工具，围绕四步流程展开：选择文件、联网检索、确认可编辑的 Dublin Core 字段、再按最新写入的元数据重命名。

### ✨ 功能亮点

- 🔎 根据文件名和 PDF 内容提示检索元数据
- 🌐 聚合 `Google Books`、`Open Library`、`豆瓣网页搜索`、`Library of Congress`
- 🧩 按 `ISBN -> DOI -> 标题 + 作者` 去重并合并候选
- 🏷️ 写入前可手动编辑 Dublin Core 字段
- ✅ 按确认后的字段值写回 PDF 元数据
- 📝 基于最新写入的元数据生成建议文件名
- ✍️ 重命名时允许再次手动修改最终文件名
- 🌗 支持 `日光 / 月光` 外观
- 🌍 支持中英文界面

### 🖼️ 截图

- 英文界面截图：见上方 `English UI`
- 中文界面截图：见上方 `Chinese UI`

### 📊 功能对比表

| 功能 | 支持情况 | 说明 |
| --- | --- | --- |
| 多源元数据检索 | ✅ | 支持 `Google Books`、`Open Library`、`Douban`、`Library of Congress` |
| 候选去重与合并 | ✅ | 优先级为 `ISBN -> DOI -> 标题 + 作者` |
| Dublin Core 字段可编辑 | ✅ | 写入前可逐项确认和修正 |
| 按确认值写入元数据 | ✅ | 第 3 步确认后的值会被直接写入 PDF |
| 基于最新元数据重命名 | ✅ | 第 4 步建议文件名来自最新写入结果 |
| 最终文件名可手动修改 | ✅ | 执行重命名前仍可再次编辑 |
| 日光 / 月光主题 | ✅ | 同时适配亮色和暗色桌面 |
| 中英文界面 | ✅ | 适合本地和国际化使用 |

### ❓ 常见问题

1. **会上传 PDF 文件吗？**  
   不会。应用只处理你在本机明确选中的 PDF，并在需要时把标题、作者、ISBN、DOI 这类检索线索发给公开元数据源，不会上传整份 PDF 文件。

2. **写入前可以手动修改字段吗？**  
   可以。第 3 步就是可编辑确认页，写入时会严格使用你确认后的字段值。

3. **重命名会基于最新写入的元数据吗？**  
   会。第 4 步建议文件名基于刚写入 PDF 的最新元数据生成，不会回退到旧候选值。

4. **最终文件名还能手动改吗？**  
   可以。第 4 步仍然允许手动修改最终文件名，然后再执行重命名。

5. **这个应用适合什么 PDF？**  
   它主要适合书籍 PDF、学术论文和参考资料这类需要整理元数据与文件名的文档。

### ⬇️ 下载

- [最新版本](https://github.com/LarryHu1988/PDFLibrarian/releases)
- 当前正式版本：`V1.0.0`
- 发布产物：`PDFLibrarian-1.0.0.dmg` 和 `PDFLibrarian-1.0.0.zip`

### 🧭 使用流程

1. 选择 PDF 文件或文件夹
2. 联网检索并合并候选元数据
3. 编辑并确认写入 Dublin Core 字段
4. 确认或修改最终文件名后执行重命名

### 🏷️ 默认写入字段

`dc:title`、`dc:creator`、`dc:publisher`、`dc:date`、`dc:language`、`dc:type`、`dc:format`、`dc:identifier`、`dc:subject`

### 🛠️ 从源码构建

```bash
swift build
./scripts/package_app.sh
./scripts/build_release_assets.sh
```

构建产物位于 `dist/`。

### 📄 许可证

本仓库采用专有、保留所有权利的授权方式。详见 [`LICENSE`](LICENSE)。
