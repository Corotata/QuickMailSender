# QuickMailSender 接入与维护指南

## 定位与权威入口

这是 iOS/macOS 的 Swift Package：创建邮件编辑页面、可选反馈确认界面、显式文件路径 ZIP 打包。用户最终决定发送；库不会自动发送邮件，也不采集宿主数据库、书籍或日志。

- 公开能力和宿主权限：`README.md`。
- 确认界面及外部文案：`Sources/QuickMailSender/FeedbackConfirmationView.swift`。
- 通用 ZIP：`Sources/QuickMailSender/FeedbackArchive.swift`。
- 文件路径邮件入口：`Sources/QuickMailSender/QuickMailSender+Resources.swift`。
- 原有邮件配置及入口：`Sources/QuickMailSender/QuickMailSender.swift`。
- 反馈类型协议和设备信息正文：`Sources/QuickMailSender/QuickMailSender+Feedback.swift`。
- Mac 邮件呈现、自动化权限与附件生命周期：`MacMailComposeSession.swift`、`MacMailAttachments.swift`。

## 新项目如何接入

1. 在宿主 `Package.swift` 添加 `https://github.com/Corotata/QuickMailSender.git`，版本至少 `1.3.0`；将产品 `QuickMailSender` 加入使用模块。App target 从模块导入 `QuickMailSender`。
2. 只需要普通邮件时，继续使用已有 `sendMail` 或 `FeedbackTypeProtocol.sendFeedback`。旧 API 不会额外弹确认框，也不要求迁移。
3. 需要前置确认时，用 SwiftUI sheet 展示 `FeedbackConfirmationView(configuration:themeColor:onConfirm:)`。标题、问题引导、附件标签、附件说明、footer、取消和继续文案全部由宿主传入并本地化；不要把产品名称或产品专属说明写到库里。主题色可传入，未传则使用宿主 `accentColor`。
4. 无文件场景把 `attachmentDescription` 设为 nil，确认页不显示附件选项。有资源时传说明，默认勾选；`includesAttachmentsByDefault` 可配置。`onConfirm` 返回是否附附件；取消或直接关闭不会回调。
5. **不要在 onConfirm 里立即打开邮件。** 先保存附件选择，等 sheet 的 `onDismiss` 再继续，避免重叠呈现。以 `Bool?` 区分取消(nil)与确认但不附文件(false)。每次打开前重置为 nil。
6. **不要提前生成业务快照或读取文件。** 只有确认且勾选后才让宿主准备 JSON、设置和经过过滤的必要日志；没有勾选就不生成/读取这些数据。库只负责压缩传入的资源，不决定该收集什么。

### 确认后调用示例

```swift
@State private var showFeedback = false
@State private var pendingIncludesFiles: Bool?

// 入口动作：pendingIncludesFiles = nil; showFeedback = true
.sheet(isPresented: $showFeedback, onDismiss: {
    guard let includeFiles = pendingIncludesFiles else { return }
    pendingIncludesFiles = nil
    // includeFiles == true 时才准备业务资源，然后调用下面的邮件接口。
    prepareAndOpenFeedback(includeFiles: includeFiles)
}) {
    FeedbackConfirmationView(
        configuration: FeedbackConfirmationConfiguration(
            title: String(localized: "向开发者反馈？"),
            message: String(localized: "遇到了什么问题？请在邮件中告诉我。"),
            attachmentLabel: String(localized: "附上诊断 ZIP"),
            attachmentDescription: resourcesAvailable ? localizedAttachmentDescription : nil,
            cancelTitle: String(localized: "取消"),
            continueTitle: String(localized: "继续反馈")
        ),
        themeColor: .accentColor
    ) { pendingIncludesFiles = $0 }
}
```

这是接入片段，宿主自行定义状态、`resourcesAvailable` 和资源准备方法，并在自己的本地化目录补齐这些文案。附件说明要列明实际内容，不能为没有收集的文件作承诺。

```swift
// files 必须是用户确认允许提供的普通文件 URL；不附文件时为 []。
QuickMailSender.default.sendMail(
    config: FeedbackMailConfig(email: developerEmail, subject: subject, body: body),
    resourceFiles: files,
    archiveName: "feedback.zip"
) { result in
    // 回到主线程更新 UI 忙碌状态，失败时展示或提供替代入口。
}
```

## ZIP 行为及所有权

- `FeedbackArchive.prepare(files:archiveName:)` 后台压缩；需要独立 ZIP 进行保存、分享或失败兜底时使用。
- `create` 是同步接口，只用于已经处于后台的处理或测试，不在 UI 主线程执行大文件压缩。
- 只接受明确列出的普通文件，不递归扫描文件夹。拒绝符号链接、非文件 URL、重复文件名（不区分大小写）及含路径的 ZIP 名称；调用方应提前为同名资源准备不同名称。
- 每轮使用独立临时目录，失败清理中间文件。源文件不被删除。
- 资源路径 `sendMail` 重载管理本轮 ZIP 的生成和清理，并保留原配置已有附件。
- 单独生成的 ZIP 由宿主在邮件交接、分享或保存完成后调用 `FeedbackArchive.remove(zipURL)` 清理；不要在交接完成前清理，不要删掉用户原始文件。
- ZIP 使用与 EPUBTranslator 兼容的 Zip 2.1.2+；附件进入现有邮件 API 前会读入 Data。不要声称支持无限大小或流式附件。

## 平台约束

### iOS

- 使用官方 `MFMailComposeViewController`，必须设置邮件代理并在完成回调里 dismiss。
- 新资源路径接口在未配置系统邮件账户时明确失败；mailto 无法带 ZIP。宿主可提供保存/分享兜底，不得静默丢弃附件。
- 旧接口的 mailto 兼容行为保持不变。
- 用户曾在 iPadOS 26.6.2 遇到无取消按钮且无法下拉的问题，根因尚未确定。前置确认只是减少误触，不代表修复系统邮件页退出问题。不要擅自更改系统邮件视图层级或承诺一定能下拉退出。

### macOS

- 明确指定 Apple 邮件，不更改默认邮件客户端。
- 无附件使用 NSWorkspace 打开标准 mailto；带附件用公开 Apple Events 创建可见邮件编辑窗口。不得加入 send、save 或 close 命令强制发送/关闭。
- 带附件宿主必须按 README 配置 `NSAppleEventsUsageDescription`、`com.apple.security.automation.apple-events` 和仅限 `com.apple.mail.compose` 的 scripting-targets。普通无附件不需 Apple Events。
- `.sent` 表示 Mail 打开/创建邮件命令完成，不代表用户发送或投递成功。
- 文本和路径通过类型化描述符传递，不拼接用户内容到脚本。拒绝授权时明确失败，不绕过系统授权。

## UI、本地化与兼容要求

- 维持原生平台附件选择控件：Mac 勾选框、iOS 开关；不强制 Mac 使用 iOS 排版。
- 附件卡片和描述行按可用宽度布局；`Spacer(minLength: 0)` 允许窄屏收缩，不只针对 Mac 做补丁。
- 底部按钮沿用 TxtToEpub 编辑页规范：headline、上下 12pt 内边距、12pt 圆角；主色填充、次色浅底描边。不要额外叠加系统按钮 padding 或固定大高度。
- 库固有用户错误通过 `String(localized:bundle:.module)` 和库目录本地化；宿主自定义文案由宿主本地化。系统 CocoaError 保留系统提供的本地化，不写死中文兜底。
- 新增公开类型、属性、方法及关键行为补注释。新增能力优先通过重载/可选参数提供，保持旧调用兼容。

## 验证与发布

- `swift test` 验证 ZIP 解压内容、源文件保留、重复名称拒绝、失败清理和现有 Mac 脚本/附件行为。历史 example 占位测试不计有效验收。
- UI 调整用隔离宿主或真实使用方验证 Mac/iOS，不自动发送测试邮件。
- 普通修改不默认提交或打 tag；明确要求发布时再提交，兼容新增接口使用 minor 版本。清晰提交日志描述问题和修复思路。
- Swift Package 的 `Package.resolved` 是本地解析产物，不随库发布；宿主 App 保留自己的 resolved 锁定文件。
