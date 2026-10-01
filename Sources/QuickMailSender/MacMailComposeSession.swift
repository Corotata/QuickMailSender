#if os(macOS)
import AppKit
import Carbon

/// Apple 邮件不可用、重复请求或附件名称无效时的明确错误。
enum MacMailSharingError: LocalizedError {
    /// 当前发送器已有邮件正在交接。
    case alreadySharing
    /// 系统未安装 Apple 邮件。
    case unavailable
    /// 附件没有有效文件名。
    case invalidFileName

    /// 可供调用方展示的错误说明。
    var errorDescription: String? {
        switch self {
        case .alreadySharing: return String(localized: "已有邮件正在打开，请稍后重试。", bundle: .module)
        case .unavailable: return String(localized: "无法打开 Apple 邮件，请检查它是否已安装并配置账户。", bundle: .module)
        case .invalidFileName: return String(localized: "邮件附件的文件名无效。", bundle: .module)
        }
    }
}

/// 单次共享所需的临时附件；每个附件使用独立目录，避免同名覆盖。
final class MacMailAttachments {
    /// 本次请求专属目录，清理时不会影响其他请求或原文件。
    let directory: URL
    /// 可供邮件共享服务读取的实际文件 URL。
    private(set) var fileURLs: [URL] = []

    /// 将现有 Data 附件写成文件，任一失败时清理全部临时文件。
    init(attachments: [EmailAttachment]) throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("QuickMailSender-\(UUID().uuidString)", isDirectory: true)
        do {
            for (index, attachment) in attachments.enumerated() {
                let name = (attachment.fileName as NSString).lastPathComponent
                guard !name.isEmpty, name != ".", name != ".." else {
                    throw MacMailSharingError.invalidFileName
                }
                let folder = directory.appendingPathComponent(String(index), isDirectory: true)
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                let file = folder.appendingPathComponent(name)
                try attachment.data.write(to: file, options: .atomic)
                fileURLs.append(file)
            }
        } catch {
            removeFiles()
            throw error
        }
    }

    /// 在邮件服务完成交接或失败后移除本次临时文件。
    func removeFiles() {
        try? FileManager.default.removeItem(at: directory)
    }

    /// 释放时兜底清理，避免失败路径留下临时附件。
    deinit { removeFiles() }
}

/// 固定的 Apple 邮件撰写脚本；用户文本作为参数传递，不能成为脚本代码。
enum AppleMailDraftScript {
    /// 仅创建并显示邮件草稿，不执行 send，也不读取收件箱。
    static let source = """
    on createDraft(recipientAddress, mailSubject, mailBody, attachmentFiles)
        tell application id "com.apple.mail"
            set draftMessage to make new outgoing message with properties {subject:mailSubject, content:mailBody, visible:true}
            tell draftMessage
                make new to recipient at end of to recipients with properties {address:recipientAddress}
                repeat with attachmentFile in attachmentFiles
                    tell content
                        make new attachment with properties {file name:contents of attachmentFile} at after last paragraph
                    end tell
                end repeat
            end tell
            return id of draftMessage
        end tell
    end createDraft
    """

    /// 用类型化描述符传入中文、换行、引号及文件 URL，避免拼接注入和路径歧义。
    static func event(config: FeedbackMailConfig, fileURLs: [URL]) -> NSAppleEventDescriptor {
        let event = NSAppleEventDescriptor(eventClass: AEEventClass(kASAppleScriptSuite),
            eventID: AEEventID(kASSubroutineEvent), targetDescriptor: nil,
            returnID: AEReturnID(kAutoGenerateReturnID), transactionID: AETransactionID(kAnyTransactionID))
        event.setParam(NSAppleEventDescriptor(string: "createDraft"), forKeyword: AEKeyword(keyASSubroutineName))
        let arguments = NSAppleEventDescriptor.list()
        arguments.insert(NSAppleEventDescriptor(string: config.email), at: 1)
        arguments.insert(NSAppleEventDescriptor(string: config.subject), at: 2)
        arguments.insert(NSAppleEventDescriptor(string: config.body), at: 3)
        let files = NSAppleEventDescriptor.list()
        for (index, url) in fileURLs.enumerated() {
            files.insert(NSAppleEventDescriptor(fileURL: url), at: index + 1)
        }
        arguments.insert(files, at: 4)
        event.setParam(arguments, forKeyword: AEKeyword(keyDirectObject))
        return event
    }

    /// 普通反馈使用标准 mailto 内容，但由调用方明确交给 Apple 邮件。
    static func mailURL(config: FeedbackMailConfig) throws -> URL {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = config.email
        components.queryItems = [
            URLQueryItem(name: "subject", value: config.subject),
            URLQueryItem(name: "body", value: config.body)
        ]
        guard let url = components.url else { throw MacMailSharingError.unavailable }
        return url
    }

    /// 串行后台队列；Apple 官方要求后台脚本工作保持串行，避免阻塞界面。
    private static let executionQueue = DispatchQueue(label: "QuickMailSender.AppleMailDraft", qos: .userInitiated)

    /// 文件写入、编译与等待 Mail 响应均在后台完成，描述符不跨线程传递。
    static func createDraft(config: FeedbackMailConfig) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            executionQueue.async {
                do {
                    let attachments = try MacMailAttachments(attachments: config.attachments ?? [])
                    defer { attachments.removeFiles() }
                    guard let script = NSAppleScript(source: source) else {
                        throw MacMailSharingError.unavailable
                    }
                    var scriptError: NSDictionary?
                    let result = script.executeAppleEvent(event(config: config, fileURLs: attachments.fileURLs), error: &scriptError)
                    guard scriptError == nil, result.descriptorType != DescType(typeNull) else {
                        throw error(scriptError)
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// 只返回错误码和系统说明，不把邮件正文或脚本参数写入日志。
    static func error(_ info: NSDictionary?) -> NSError {
        let number = (info?[NSAppleScript.errorNumber] as? NSNumber)?.intValue ?? -1
        let reason = info?[NSAppleScript.errorMessage] as? String ?? String(localized: "无法创建 Apple 邮件草稿。", bundle: .module)
        let message = number == -1743
            ? String(localized: "未获准创建 Apple 邮件草稿。请在系统设置的隐私与安全性→自动化中允许此应用控制邮件。", bundle: .module)
            : reason
        return NSError(domain: "QuickMailSender.AppleMail", code: number,
            userInfo: [NSLocalizedDescriptionKey: message])
    }
}

/// 指定 Apple 邮件的单次撰写会话；后台工作结束后回主线程报告结果。
@MainActor
final class MacMailComposeSession {
    /// 只调用一次的结果回调。
    private var completion: ((MailSendResult) -> Void)?

    /// 创建本次邮件会话。
    init(completion: @escaping (MailSendResult) -> Void) {
        self.completion = completion
    }

    /// 明确启动 Apple 邮件，再创建带附件的草稿；首次系统授权由用户确认。
    func start(config: FeedbackMailConfig) {
        Task { @MainActor in
            do {
                guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.mail") else {
                    throw MacMailSharingError.unavailable
                }
                let options = NSWorkspace.OpenConfiguration()
                if config.attachments?.isEmpty != false {
                    // 普通反馈直接请求 Mail 的写邮件窗口，避免先启动主窗口再脚本创建。
                    options.activates = true
                    _ = try await NSWorkspace.shared.open([AppleMailDraftScript.mailURL(config: config)],
                        withApplicationAt: appURL, configuration: options)
                } else {
                    // 启动时不抢到草稿列表；只在带附件的新邮件创建后激活 Mail。
                    options.activates = false
                    let mail = try await NSWorkspace.shared.openApplication(at: appURL, configuration: options)
                    try await AppleMailDraftScript.createDraft(config: config)
                    mail.activate(options: .activateAllWindows)
                }
                // sent 表示打开/创建请求完成，不代表用户已发送。
                finish(.sent)
            } catch {
                finish(.failed(error))
            }
        }
    }

    /// 命令完成后清理临时文件；失败不能退回 Chrome 或丢失附件的 mailto。
    private func finish(_ result: MailSendResult) {
        guard let completion else { return }
        self.completion = nil
        completion(result)
    }
}
#endif
