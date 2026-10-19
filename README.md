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

### macOS 新项目接入核对（必做）

先配置宿主，再验证带附件路径。只验证普通反馈、ZIP 生成或编译成功，不能证明带附件邮件可用。

1. 在 Mac App 实际使用的 entitlements 文件中合并以下声明；保留宿主已有权限：

   ```xml
   <key>com.apple.security.automation.apple-events</key>
   <true/>
   <key>com.apple.security.scripting-targets</key>
   <dict>
       <key>com.apple.mail</key>
       <array>
           <string>com.apple.mail.compose</string>
       </array>
   </dict>
   ```

2. Info.plist 配置 `NSAppleEventsUsageDescription`，例如“用于创建反馈邮件并附加您确认提供的诊断文件。”使用生成 Info.plist 时，对应构建设置为 `INFOPLIST_KEY_NSAppleEventsUsageDescription`；界面文案由宿主本地化。
3. 核对 Debug 与 Release 的 `CODE_SIGN_ENTITLEMENTS` 都指向正确文件。跨平台 target 可分别配置 `CODE_SIGN_ENTITLEMENTS[sdk=macosx*]` 和 `INFOPLIST_KEY_NSAppleEventsUsageDescription[sdk=macosx*]`，避免只改了 iOS 文件或未被 target 使用的文件。
4. 重新构建并启动本次产物。对普通签名构建执行下列只读检查，确认最终 App 内确实含有上述两项权限、Mail 撰写组和用途说明：

   ```sh
   # 将路径替换为当前 Debug 或归档后的 App；不要检查旧产物。
   codesign -d --entitlements - "/实际路径/YourApp.app"
   /usr/libexec/PlistBuddy -c 'Print :NSAppleEventsUsageDescription' "/实际路径/YourApp.app/Contents/Info.plist"
   ```

   Xcode 测试宿主可能注入临时权限，不能代替普通 App 的签名核对与实际验收。不要通过关闭 App Sandbox、增加全盘读取权限或临时 Apple Events 例外解决接线问题。

### macOS 常见故障与定位顺序

| 现象 | 先核对什么 |
| --- | --- |
| Mail 已运行，仍报“应用程序没有运行” | 先检查最终 App 签名是否缺少 `com.apple.security.scripting-targets` 中的 `com.apple.mail.compose`。EPUB OMG 曾因漏配此项出现该错误；该错误文字不能单独证明 Mail 没启动。 |
| 无附件正常，带附件失败 | 两者使用不同路径：无附件为 NSWorkspace + mailto，附件为 Apple Events。核对三项宿主配置及最终签名，再检查授权与附件可读性。 |
| 报未授权 / `QuickMailSender.AppleMail` 错误码 `-1743` | 配置正确后，由用户在“系统设置 → 隐私与安全性 → 自动化”确认允许宿主控制邮件；不绕过或自动重置授权。 |
| 暂时只看到 Mail 原窗口或其他项目的草稿 | 等待交接回调，并从 Mail“窗口”菜单按本次唯一主题定位；不要仅凭最前面的窗口判定失败。期间阻止重复点击，并展示忙碌状态。 |
| 创建失败 | 展示真实错误，保留可重试资源；宿主可提供保存 ZIP 的兜底。不要退回无法携带附件的 mailto 后报告成功。 |

### 带附件流程的完成标准

每个新宿主至少用一份无私人内容、带中文文件名的测试文件，走一次真实产品入口：

1. 触发业务错误 → 打开反馈确认 → 勾选附件 → 关闭确认页后调用公共邮件接口；取消确认不打开邮件。
2. 用普通签名 App 创建 Mail 草稿，确认收件人、唯一主题、错误信息、文件名及 ZIP 附件可见。遇到系统授权提示由用户确认。
3. 用 Mail 的“存储附件”保存 ZIP，在本机解包；核对文件名、大小及内容哈希或逐字节一致。附件图标出现不等于内容完整。
4. 确认交接完成后 UI 解除忙碌，临时副本按所有权清理，用户原文件仍在；失败时能显示错误并重试。
5. 记录实际验证的 App、构建配置和结果；保留为未发送草稿供检查，不自动发送测试邮件。`.sent` 只说明邮件交接命令完成。

自动测试应覆盖业务资源暂存 → `FeedbackArchive` → 解包一致性及原文件保留；此测试与脚本编译测试均不能替代真实 Mail 草稿验收。

**已验证经验（2026-10-19）：** EPUB OMG 补齐 Mail 撰写权限后，普通签名 Debug App 成功创建带约 2.1 MB ZIP 的反馈草稿。从 Mail 保存附件并以 macOS `ditto` 解包后，中文 EPUB 文件名、2,098,834 字节及 SHA-256 均与原测试文件一致；未发送邮件。EPUBTranslator 也已声明同一组 macOS 权限，使用现成 ZIP 附件入口；两种打包入口最终复用同一 macOS 草稿实现。

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
    // 处理平台交接结果；macOS 的 .sent 仅表示草稿创建命令完成。
}

// 应用需要保存、分享 ZIP 或提供失败兜底时，单独生成文件。
let zipURL = try await FeedbackArchive.prepare(files: resources, archiveName: "feedback.zip")
// 完成邮件交接或保存后清理，原始文件不会被删除。
FeedbackArchive.remove(zipURL)
```

库只接受明确列出的普通文件，不递归扫描目录；同名文件报错以避免遗漏。每次 ZIP 使用独立临时目录，失败清理中间文件。路径入口生成的附件与现有附件合并；空资源列表沿用原有无新增附件流程。书籍 JSON、日志过滤和数据库快照仍由宿主应用准备，库不采集业务数据。ZIP 使用 Zip 2.1.2 及以上兼容版本。API 报错继续通过 `.failed(error)` 回报。

新增资源路径入口在 iOS 未配置系统邮件账户时明确失败，不通过无法携带附件的 mailto 静默丢弃 ZIP；宿主可选择分享或保存文件作为兜底。旧接口行为保持兼容。

确认界面另支持 `FeedbackConfirmationView(configuration: configuration, themeColor: .mint, onConfirm: ...)`：主题色由宿主传入，默认使用宿主 `accentColor`。底部两个等宽按钮沿用 TxtToEpub 编辑页的 headline、12pt 上下内边距、12pt 圆角；主操作为实色，次操作为浅底描边。
