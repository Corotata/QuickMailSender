QuickMailSender

QuickMailSender 是一个开箱即用的邮件组件，专为日常开发中的反馈需求设计。它能够快速集成到你的应用中，帮助用户便捷地提交问题反馈。

1. 内置基础模板，开箱即用。
2. 支持多语言本地化，自动适配用户环境。

```
// 英文展示效果如下：
Current Date: 2024-09-30 23:28:05
App Name: QuickMailSenderExample
App Version: 1.0 (1)
Device Model: Macmini9,1
Operating System: Version 14.5 (Build 23F79)

Content Module: 通用
Error Message: 你犯了无可避免的错误
Related Parameters:
{
  "timestamp" : 1727710085.556509
}

Feedback: 


// 中文展示效果如下：
当前日期: 2024-09-30 23:29:04
应用名称: QuickMailSenderExample
应用版本: 1.0 (1)
设备型号: Macmini9,1
操作系统: 版本14.5（版号23F79）

内容模块: 
相关参数:
{
  "timestamp" : 1727710144.076499
}

反馈内容: 


```

## 安装

### Swift Package Manager

1. 在Xcode中，选择 File > Swift Packages > Add Package Dependency
2. 输入仓库URL: `[https://github.com/corotata/QuickMailSender.git](https://github.com/Corotata/QuickMailSender)`
3. 选择版本规则，建议使用最新版本

## 使用示例

首先，导入 QuickMailSender 模块：

```
import QuickMailSender
```

然后，使用下面的代码示例：

```
import SwiftUI
import QuickMailSender

@available(iOS 15.0, macOS 13.0, *)
public struct FeedbackView: View {
    @State private var recipientEmail = "support@example.com"
    @State private var subject = "应用反馈"
    @State private var mainName = "通用"
    @State private var errorInfo = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private let sender = PlatformMailSender()
    
    public var body: some View {
        Form {
            Section(header: Text("邮件设置")) {
                TextField("收件人邮箱", text: $recipientEmail)
                TextField("主题", text: $subject)
            }
            
            Section(header: Text("反馈信息")) {
                TextField("模块名称", text: $mainName)
                TextField("错误信息 (可选)", text: $errorInfo)
            }
            
            Section {
                Button("发送反馈") {
                    sendFeedback()
                }
            }
        }
        .padding()
        .alert("提示", isPresented: $showAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func sendFeedback() {
        let main = DefaultFeedbackModule(
            moduleName: mainName,
            errorInfo: errorInfo.isEmpty ? nil : errorInfo,
            requestParameters: ["timestamp": Date().timeIntervalSince1970]
        )
        
        let config = FeedbackMailConfig.mailConfig(
            to: recipientEmail,
            subject: subject.isEmpty ? nil : subject,
            feedbackModule: main
        )
        
        sender.sendMail(config: config) { result in
            DispatchQueue.main.async {
            		//可通过result处理相应的弹框提示，result.description已内嵌了相应的内容
                showAlert(message: result.description)
            }
        }
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}

@available(iOS 15.0, macOS 13.0, *)
struct ContentView: View {
    var body: some View {
        #if canImport(AppKit)
        FeedbackView()
            .navigationTitle("反馈")
        #else
        NavigationView {
            FeedbackView()
                .navigationTitle("反馈")
        }
        #endif
    }
}

#Preview {
    ContentView()
}
```

## 注意事项

- 在 iOS 设备上，如果用户没有设置邮件账户，组件会自动打开 `mailto:` URL。
- 在 macOS 上，组件明确使用 Apple 邮件。无附件邮件通过 NSWorkspace 将标准 mailto 交给 Apple 邮件，直接打开写邮件窗口；带附件邮件通过受限 Apple Events 创建可见的新邮件并添加附件，完成后激活 Mail。带附件流程需要用户授权自动化。失败通过 `.failed(error)` 回报，调用方可以提供保存附件等兜底。
- macOS 的 `.sent` 表示打开邮件或创建草稿的命令完成，不保证用户已点击发送或邮件已送达。库会保留临时附件到创建命令完成，再清理本次请求的临时文件。

### macOS 宿主权限配置

带附件流程的权限需要由使用库的 App 声明，Swift Package 无法替宿主申请。仅在使用此功能的 Mac target 配置：

- Info.plist：`NSAppleEventsUsageDescription`，解释创建反馈邮件及附件的用途。
- Hardened Runtime：`com.apple.security.automation.apple-events = true`。
- App Sandbox：`com.apple.security.scripting-targets = { "com.apple.mail": ["com.apple.mail.compose"] }`，限制为邮件撰写组，不申请读取邮箱权限或临时例外。

首次使用带附件邮件由系统提示用户授权；普通无附件反馈不需要 Apple Events 授权。拒绝后库明确失败，不绕过授权，不改变默认邮件程序。脚本只创建并显示草稿，不执行发送命令。

## 可选反馈确认与资源 ZIP

旧的 `sendMail` / `sendFeedback` 保持不变，不会自动多弹一个确认框。需要确认时，以 sheet 呈现 `FeedbackConfirmationView`，通过 `FeedbackConfirmationConfiguration` 传入已本地化的标题、问题引导、按钮文案及附件说明。`attachmentDescription` 为 nil 时只显示普通反馈；有说明时显示默认勾选的附件选项。

`onConfirm` 回传是否附带资源。建议先关闭确认 sheet，在 sheet 的 `onDismiss` 中继续，以免邮件与确认界面同时呈现。取消或直接关闭确认框不会触发 `onConfirm`，不应生成附件或打开邮件。

文件打包有两种使用方式：

```swift
// 已确认且勾选附件：库压缩明确提供的文件，在后台读取 ZIP，然后打开邮件。
QuickMailSender.default.sendMail(
    config: mailConfig,
    resourceFiles: includeFiles ? [originalURL, translationsJSONURL, settingsURL] : [],
    archiveName: "feedback.zip"
) { result in
    // 用户完成邮件操作后处理状态；这不是自动发送接口。
}

// 应用需要保存、分享 ZIP 或提供失败兜底时，单独生成文件。
let zipURL = try await FeedbackArchive.prepare(files: resources, archiveName: "feedback.zip")
// 完成邮件交接或保存后清理，原始文件不会被删除。
FeedbackArchive.remove(zipURL)
```

库只接受明确列出的普通文件，不递归扫描目录；同名文件报错以避免遗漏。每次 ZIP 使用独立临时目录，失败清理中间文件。路径入口生成的附件与现有附件合并；空资源列表沿用原有无新增附件流程。书籍 JSON、日志过滤和数据库快照仍由宿主应用准备，库不采集业务数据。ZIP 使用 Zip 2.1.2 及以上兼容版本。API 报错继续通过 `.failed(error)` 回报。

新增资源路径入口在 iOS 未配置系统邮件账户时明确失败，不通过无法携带附件的 mailto 静默丢弃 ZIP；宿主可选择分享或保存文件作为兜底。旧接口行为保持兼容。

确认界面另支持 `FeedbackConfirmationView(configuration: configuration, themeColor: .mint, onConfirm: ...)`：主题色由宿主传入，默认使用宿主 `accentColor`。底部两个等宽按钮沿用 TxtToEpub 编辑页的 headline、12pt 上下内边距、12pt 圆角；主操作为实色，次操作为浅底描边。
