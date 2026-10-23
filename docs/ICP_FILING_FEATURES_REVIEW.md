# PDF Librarian：App 备案特征信息

本页保留 1.0.0 / 1.0.1 构建的历史签名记录。新修复版 1.0.1 / 1.0.2 使用另一张团队分发证书，完整参数另见 [1.0.1 签名包与备案参数](ICP_FILING_FEATURES_1.0.1.md)。

核对日期：2026-10-18。当前 App Store Connect 分发签名信息已从实际导出包确认。网页已填写，保存尚未确认，未提交备案。

## 填写值

| 字段 | 填写内容 |
| --- | --- |
| 运行平台 | 其他平台 |
| 平台名称 | macOS |
| 其他平台软件包名称 | `com.larry.pdflibrarian` |
| 证书 MD5 指纹 | `85AA0A2C3A977E6EC271DFBEA402B6C5` |
| 证书 SHA-1（留存核对，不填入 32 位 MD5 栏） | `868BDF320F0C3B7ED4123D890155A6D9BCC0DA74` |
| 证书类型 | Cloud Managed Apple Distribution |
| 版本 / 构建 | 1.0.0 / 1.0.1 |

公钥：完整 PKCS#1 RSAPublicKey DER 十六进制，540 字符，不带空格、冒号或 PEM 头尾：

```text
3082010A0282010100E3B8DB7906B366A4F33FFF1A650FE5FEF5E61C566DC57D0BCF8E51B22C41B762EEE5314B974887EBC885973780D217DF963299F803FC4C4A56535951FA38C0A91355FF138A514DC60B01B8499D5841ADEE435C390B0FAB0EA1C428520A859E9AB3DA63EAE75FEB7684ED03CB3A5CA4874581AA5235D9908DE653574F2E334175E4DCC4A181546396305710C4E25DB2832BD0D0B7DF61E37678691D5BCC8DBBA085D8BFC43B2A430035BE8E1CBB6B16DBC101376970B62A7525189C0C7B1103DC0830F46A3AA694AFD5E2EDCD6B264833E3B15F28520A9C2C9029AAA1314C68EF175CEA97F1B5EE31D8A5B92133A034BA26350AE4873ACDA4C513AF569EB838430203010001
```

## 确认依据

1. App Store Connect 当前可分发 macOS 版本为 1.0.0，构建 1.0.1，Bundle ID 为 com.larry.pdflibrarian。
2. 用户完成 Xcode 登录后，从原始归档执行 App Store Connect 分发导出，destination=export，仅保存本地，没有上传新构建。
3. 解包签名 PKG 后，从内部 App 的实际代码签名提取叶证书，计算 SHA-1、MD5 及公钥。
4. 又以不指定任何证书指纹的自动签名设置独立导出，DistributionSummary.plist 自动选择的 SHA-1 与提取证书一致：868BDF320F0C3B7ED4123D890155A6D9BCC0DA74。
5. PKG 安装器的叶证书 SHA-1 是 A677C2C9E84CA690AEBB56C05B9E0C7D735397B0，与历史上传记录一致。因此先前遇到的 A677 开头标识是安装器证书，不是应该填写的 App 应用分发证书。
6. 原先候选 1 的 B04E88DF3F311C001BC3366765D99EAAAD142106 未被当前 Xcode 自动分发导出选用；本次填写使用上面的实际应用签名证书。

证据保存目录：`/Users/larry/Library/Mobile Documents/com~apple~CloudDocs/1_项目_Projects/14_PDFLibrarian/dist/icp-verification-2026-10-18`。包含签名 PKG、公开证书、自动导出摘要、导出选项、日志及 icp-features.json；不含导出的私钥。

## 提取命令

```sh
codesign -d --extract-certificates=/tmp/pdflibrarian-cert- "/path/to/distribution/PDF Librarian.app"
openssl x509 -inform DER -in /tmp/pdflibrarian-cert-0 -noout -fingerprint -md5
openssl x509 -inform DER -in /tmp/pdflibrarian-cert-0 -pubkey -noout | openssl rsa -pubin -RSAPublicKey_out -outform DER | xxd -p -c 4096
```

## 表单状态

- 已在原 Safari 备案页面填入上述包名、公钥和 32 位证书 MD5。
- 未提交备案订单。
- 浏览器自动点击保存控件受限，尚未取得保存成功回执。请勿把“已输入”视为“已保存”。

## 官方说明

- [阿里云：填写 App 特征信息](https://help.aliyun.com/zh/icp-filing/basic-icp-service/user-guide/fill-in-app-feature-information)：公钥和指纹来自对应签名证书。文档的 iOS SHA-1 说明不等于当前 macOS 其他平台表单的 MD5 字段；本次按当前表单填写 32 位 MD5。
- [Apple：分发签名](https://help.apple.com/xcode/mac/current/en.lproj/devcac6ab5b3.html)：macOS 应用分发证书与安装器证书分别选择。
