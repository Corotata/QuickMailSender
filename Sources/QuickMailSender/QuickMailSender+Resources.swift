import Foundation
#if canImport(MessageUI)
import MessageUI
#endif

public extension QuickMailSender {
    /// 将明确选择的资源路径打包后打开邮件；空列表沿用无附件路径，旧 API 不变。
    /// 确认界面的取消选择由调用方传入空列表，库不会读取未选择的文件。
    @MainActor
    func sendMail(config: FeedbackMailConfig, resourceFiles: [URL],
                  archiveName: String = "feedback.zip",
                  completion: @escaping @Sendable (MailSendResult) -> Void) {
        guard !resourceFiles.isEmpty else {
            sendMail(config: config, completion: completion)
            return
        }
#if canImport(MessageUI)
        // mailto 无法携带 ZIP；新增路径接口明确失败，供宿主选择分享或保存兜底。
        guard MFMailComposeViewController.canSendMail() else {
            completion(.failed(CocoaError(.featureUnsupported)))
            return
        }
#endif
        Task {
            do {
                let archive = try await FeedbackArchive.prepare(files: resourceFiles, archiveName: archiveName)
                defer { FeedbackArchive.remove(archive) }
                let attachment = try await Task.detached(priority: .utility) {
                    EmailAttachment(data: try Data(contentsOf: archive), mimeType: "application/zip", fileName: archive.lastPathComponent)
                }.value
                let updated = FeedbackMailConfig(email: config.email, subject: config.subject, body: config.body,
                                                 attachments: (config.attachments ?? []) + [attachment])
                // 下层会话拥有附件数据或副本，因此可清理本轮 ZIP；不删除原始资源。
                sendMail(config: updated, completion: completion)
            } catch {
                completion(.failed(error))
            }
        }
    }
}
