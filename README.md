我想现这开源，用于支持SwiftUI上可以很方便发送邮件

# SwiftUI邮件发送组件

这是一个简单易用的SwiftUI邮件发送组件，可以让你在SwiftUI应用中方便地发送邮件。

## 功能特点

- 支持纯文本和HTML格式的邮件内容
- 可添加多个收件人、抄送和密送
- 支持添加附件
- 使用系统邮件界面发送，无需额外配置

## 安装

### Swift Package Manager

1. 在Xcode中，选择 File > Swift Packages > Add Package Dependency
2. 输入仓库URL: `https://github.com/你的用户名/SwiftUIMailSender.git`
3. 选择版本规则，建议使用最新版本

## 使用示例

首先，导入 QuickMailSender 模块：

```
import QuickMailSender
```

然后，创建一个 `FeedbackMailConfig` 实例：

```
let mailConfig = FeedbackMailConfig(
    email: "example@example.com",
    subject: "Test Subject",
    body: "Test Body"
)
```

接下来，创建一个 `PlatformMailSender` 实例：

```
let mailSender = PlatformMailSender()
```

最后，在你的 SwiftUI 视图中使用 `Button` 触发邮件发送

```
struct ContentView: View {
    @State private var mailSender = PlatformMailSender()
    var body: some View {
        Button("发送反馈") {
            Task {
    await mailSender.sendMail(config: mailConfig)
            }
        }
    }
}
```

如果你想使用更高级的功能，比如添加附件或自定义邮件内容，可以使用 `FeedbackMailComposer`：

```
let mailComposer = FeedbackMailComposer()
mailComposer.mailComposeDelegate = self
mailComposer.setToRecipients(["example@example.com"])
mailComposer.setSubject("Test Subject")
mailComposer.setMessageBody("Test Body", isHTML: false)
mailComposer.addAttachmentData(Data(), mimeType: "text/plain", fileName: "attachment.txt")

```

## 注意事项

- 在 iOS 设备上，如果用户没有设置邮件账户，组件会自动打开 `mailto:` URL。
- 在 macOS 上，组件会直接打开默认邮件客户端。

## 贡献

欢迎提交 issues 和 pull requests 来帮助改进这个项目。

## 许可证

本项目采用 MIT 许可证。详情请见 [LICENSE](LICENSE) 文件。