# App Store Connect 中文提交流程与可复制材料

更新日期：2026-03-11

## 一、你现在可以直接填写的网址

如果 GitHub Pages 启用成功，填写下面这两个：

- 隐私政策网址：`https://larryhu1988.github.io/PDFLibrarian/privacy-policy/`
- 支持网址：`https://larryhu1988.github.io/PDFLibrarian/support/`

其他可用网址：

- Release Notes：`https://github.com/LarryHu1988/PDFLibrarian/releases/tag/V1.0.0`
- Issues 支持入口：`https://github.com/LarryHu1988/PDFLibrarian/issues`
- 下载页：`https://github.com/LarryHu1988/PDFLibrarian/releases`

## 二、分发信息

### 1. 内容版权

选择：

`是，它包含、显示或会访问第三方内容，并且我拥有相应内容的必要版权`

### 2. 年龄分级

按下面填写，目标分级为 `4+`：

- 不受限网页访问：`否`
- 用户生成内容：`否`
- 消息和聊天：`否`
- 广告：`否`
- 粗俗语言或低俗幽默：`无`
- 恐怖或惊悚主题：`无`
- 酒精、烟草或药物使用或提及：`无`
- 健康与医疗信息：`无`
- 性暗示主题：`无`
- 色情或裸露：`无`
- 卡通或幻想暴力：`无`
- 武器：`无`
- 真实暴力：`无`
- 赌博：`否`
- 模拟赌博：`无`
- 盲盒：`否`
- 面向儿童：`不适用`
- 覆盖为更高年龄分级：`否`

### 3. 出口合规性 / 加密

按当前实现，选择方向为：

- 不需要额外加密文稿
- 不使用专有加密
- 不在 Apple 系统加密之外额外实现标准加密

说明：

- `Info.plist` 已设置 `ITSAppUsesNonExemptEncryption = false`
- 当前代码未使用 `CryptoKit`、`CommonCrypto`、`OpenSSL`

## 三、综合 > App 信息

### 1. 名称

`PDF Librarian`

### 2. 主要类别

`效率`

### 3. 隐私政策网址

复制：

```text
https://larryhu1988.github.io/PDFLibrarian/privacy-policy/
```

### 4. 支持网址

复制：

```text
https://larryhu1988.github.io/PDFLibrarian/support/
```

### 5. 版权

可以填写：

```text
2026 PDF Librarian. All rights reserved.
```

## 四、综合 > App 隐私

首次上架建议按保守方式填写：

### 1. 是否收集任何数据？

选择：

`是，我们会从这个 App 收集数据`

### 2. 数据类型

建议只申报：

- `用户内容`
- 更接近的子类可选：`其他用户内容`

### 3. 用途

选择：

- `App 功能`

### 4. 是否与用户身份关联

选择：

- `否`

### 5. 是否用于跟踪

选择：

- `否`

### 6. 不要勾选的类型

- 联系信息
- 位置
- 财务信息
- 健康与健身
- 购买记录
- 浏览历史
- 搜索历史
- 标识符
- 使用数据
- 诊断
- 敏感信息

## 五、价格与销售范围

### 1. 分发方式

选择：

`公开分发`

### 2. App 供应情况

选择：

`所有国家或地区`

### 3. 价格

建议：

- 基准国家或地区：`中国大陆`
- 价格：`CNY 19.90` 对应档位

如果价格档位里没有 `19.90`，选最接近的一档。

## 六、版本页（macOS 1.0.0）可直接复制的文案

### 1. 简体中文

#### 副标题

```text
图书与文献 PDF 元数据管理
```

#### 推广文案

```text
一键检索并写入书籍/文献元数据，按标准规则重命名，打造可维护的 PDF 资料库。
```

#### 详细介绍

```text
PDF Librarian 是一款面向 macOS 的书籍/文献 PDF 元数据管理工具。你可以从文件名和内容提示出发，在线检索多个权威来源的元数据，并在确认后将 Dublin Core 字段写入 PDF 文件内部。

核心能力：
- 多源检索与字段合并（Google Books、Open Library、豆瓣网页、Library of Congress）
- 按 ISBN/DOI/标题+作者进行去重与候选排序
- 写入前可手动编辑字段，支持字段级勾选写入
- 写入前清理旧元数据，确保结果一致
- 按书名、作者、出版社、出版年、语言等信息进行标准化重命名
- 支持多语言 UI 和日光/月光外观切换

适合：
- 个人数字图书馆整理
- 学术论文与参考文献管理
- 团队共享资料的统一命名和元数据规范化
```

#### 关键词

```text
pdf,元数据,dublin core,图书管理,文献管理,重命名,书籍,学术,metadata
```

### 2. English (U.S.)

#### Subtitle

```text
Metadata Manager for Book & Paper PDFs
```

#### Promotional Text

```text
Search, merge, and write accurate PDF metadata, then rename files with a consistent library rule.
```

#### Description

```text
PDF Librarian is a macOS app for managing metadata of book and academic paper PDFs. It searches multiple metadata sources from filename and content hints, then lets you review and write Dublin Core fields directly into PDF files.

Key capabilities:
- Multi-source lookup and field merge (Google Books, Open Library, Douban web search, Library of Congress)
- Deduplication and ranking by ISBN, DOI, title, and author
- Manual field editing before write, with field-level selection
- Cleans old metadata before writing new values
- Standard rename workflow based on the latest confirmed metadata
- Multi-language UI with Daylight and Moonlight appearance modes

Great for:
- Personal digital library organization
- Research paper and reference collection cleanup
- Team-wide naming and metadata normalization workflows
```

#### Keywords

```text
pdf,metadata,dublin core,library,books,papers,rename,macos,document management
```

## 七、App 审核信息 > 审核备注（英文可直接复制）

```text
PDF Librarian is a macOS app for organizing book and academic paper PDFs.

How the app works:
- The app only accesses files or folders explicitly selected by the user through the standard macOS open panel.
- The app can search public metadata sources to find book or paper information, including Google Books, Open Library, Douban web search, and the Library of Congress.
- The app writes Dublin Core metadata into the selected PDF after the user reviews and confirms the final field values.
- The app can rename the selected PDF after the user confirms the final file name.

Permissions explanation:
- File access is required so the app can read the user-selected PDFs and write metadata back into those same files.
- Network access is required only to query public metadata sources requested by the user.

Important notes for review:
- No user account, login, subscription, or in-app purchase is required.
- The app does not provide user-generated content sharing or social features.
- The app does not use advertising SDKs or tracking SDKs.
```

## 八、可直接上传的 App Store 截图

官方可接受的 macOS 截图尺寸之一是：`2880 x 1800`

已生成截图文件：

### English (U.S.)

- `/Users/larry/Documents/PDF Librarian/docs/app-store/screenshots/en-US/01.png`
- `/Users/larry/Documents/PDF Librarian/docs/app-store/screenshots/en-US/02.png`
- `/Users/larry/Documents/PDF Librarian/docs/app-store/screenshots/en-US/03.png`
- `/Users/larry/Documents/PDF Librarian/docs/app-store/screenshots/en-US/04.png`

### 简体中文

- `/Users/larry/Documents/PDF Librarian/docs/app-store/screenshots/zh-Hans/01.png`
- `/Users/larry/Documents/PDF Librarian/docs/app-store/screenshots/zh-Hans/02.png`
- `/Users/larry/Documents/PDF Librarian/docs/app-store/screenshots/zh-Hans/03.png`
- `/Users/larry/Documents/PDF Librarian/docs/app-store/screenshots/zh-Hans/04.png`

## 九、宣传预览图

说明：macOS 的 `App 预览` 视频是可选项，不是必须项。这里额外准备了宣传预览图，方便你做展示、邮件或网页素材。

- `/Users/larry/Documents/PDF Librarian/docs/app-store/preview/preview-en-US.png`
- `/Users/larry/Documents/PDF Librarian/docs/app-store/preview/preview-zh-Hans.png`

## 十、最后提交顺序

1. 填完 `分发信息`
2. 填完 `综合 > App 信息`
3. 填完 `综合 > App 隐私`
4. 填完 `价格与销售范围`
5. 回到 `macOS 1.0.0` 上传中英文截图、确认文案、选择构建版本
6. 填 `App 审核信息`
7. 版本发布方式选：`手动发布此版本`
8. 点 `添加以供审核` / `提交至审核`
9. 审核通过后再点 `发布此版本`
