#if os(macOS)
import AppKit
import Testing
@testable import QuickMailSender

/// 用户字符串只作为参数传递，引号、换行及脚本片段不会进入脚本源码。
@Test func draftArgumentsPreserveTextWithoutScriptInterpolation() throws {
    let text = "中文 \"引号\" & ? \\ \n tell application \"Other\""
    let config = FeedbackMailConfig(email: "myhdify@gmail.com", subject: text, body: text)
    let url = URL(fileURLWithPath: "/private/tmp/测试附件.zip")
    let event = AppleMailDraftScript.event(config: config, fileURLs: [url])
    let parameters = try #require(event.paramDescriptor(forKeyword: 0x2d2d2d2d))
    #expect(parameters.atIndex(1)?.stringValue == config.email)
    #expect(parameters.atIndex(2)?.stringValue == text)
    #expect(parameters.atIndex(3)?.stringValue == text)
    #expect(parameters.atIndex(4)?.numberOfItems == 1)
    #expect(parameters.atIndex(4)?.atIndex(1)?.descriptorType == 0x6675726c)
    #expect(event.paramDescriptor(forKeyword: 0x736e616d)?.stringValue == "createDraft")
    #expect(!AppleMailDraftScript.source.contains(text))
}

/// mailto 的分隔符、中文、引号和换行必须保持正文，不得被拆成额外收件人字段。
@Test func plainMailURLKeepsReservedCharactersInBody() throws {
    let config = FeedbackMailConfig(email: "support+feedback@example.com", subject: "问题 & 排版？",
        body: "第一行\n&cc=other@example.com\n中文 # 内容 + 引号\"")
    let url = try AppleMailDraftScript.mailURL(config: config)
    let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
    #expect(components.scheme == "mailto")
    #expect(components.path == config.email)
    #expect(components.queryItems?.count == 2)
    #expect(components.queryItems?.first(where: { $0.name == "subject" })?.value == config.subject)
    #expect(components.queryItems?.first(where: { $0.name == "body" })?.value == config.body)
}

/// 只编译固定脚本，不执行 Apple Events，不创建或发送真实邮件。
@MainActor @Test func draftScriptCompilesWithAppleMailDictionary() throws {
    let script = try #require(NSAppleScript(source: AppleMailDraftScript.source))
    var error: NSDictionary?
    #expect(script.compileAndReturnError(&error))
    #expect(error == nil)
}

/// 拒绝控制权限时明确解释恢复路径，其他系统错误保留错误码。
@Test func automationDenialHasActionableError() {
    let error = AppleMailDraftScript.error([NSAppleScript.errorNumber: -1743])
    #expect(error.code == -1743)
    #expect(error.localizedDescription == String(localized: "未获准创建 Apple 邮件草稿。请在系统设置的隐私与安全性→自动化中允许此应用控制邮件。", bundle: .module))
    let other = AppleMailDraftScript.error([NSAppleScript.errorNumber: -10000, NSAppleScript.errorMessage: "附件不可读"])
    #expect(other.code == -10000)
    #expect(other.localizedDescription == "附件不可读")
}
#endif
