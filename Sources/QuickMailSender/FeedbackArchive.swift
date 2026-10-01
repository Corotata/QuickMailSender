import Foundation
import Zip

/// 通用反馈 ZIP：只压缩调用方明确提供的文件，不扫描用户目录。
public enum FeedbackArchive {
    /// 串行执行 Zip，避免不同反馈任务并发调用压缩库。
    private static let queue = DispatchQueue(label: "QuickMailSender.feedbackArchive", qos: .utility)

    /// 在后台生成独立 ZIP；调用方负责在交接邮件结束或保存后清理返回的临时目录。
    public static func prepare(files: [URL], archiveName: String = "feedback.zip") async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                continuation.resume(with: Result { try create(files: files, archiveName: archiveName) })
            }
        }
    }

    /// 在唯一临时目录中复制明确的普通文件，重复名称直接报错，避免覆盖或漏附件。
    public static func create(files: [URL], archiveName: String = "feedback.zip",
                              temporaryRoot: URL = FileManager.default.temporaryDirectory) throws -> URL {
        let manager = FileManager.default
        let name = URL(fileURLWithPath: archiveName).lastPathComponent
        guard !files.isEmpty, name == archiveName, name.lowercased().hasSuffix(".zip") else {
            throw CocoaError(.fileWriteInvalidFileName)
        }
        let directory = temporaryRoot.appendingPathComponent("quick_feedback_" + UUID().uuidString, isDirectory: true)
        try manager.createDirectory(at: directory, withIntermediateDirectories: true)
        var succeeded = false
        defer { if !succeeded { try? manager.removeItem(at: directory) } }
        let payload = directory.appendingPathComponent("payload", isDirectory: true)
        try manager.createDirectory(at: payload, withIntermediateDirectories: true)
        var names = Set<String>()
        var copies: [URL] = []
        for file in files {
            guard file.isFileURL else { throw CocoaError(.fileReadUnsupportedScheme) }
            let scoped = file.startAccessingSecurityScopedResource()
            defer { if scoped { file.stopAccessingSecurityScopedResource() } }
            let values = try file.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
            guard values.isRegularFile == true, values.isSymbolicLink != true else { throw CocoaError(.fileReadUnknown) }
            guard names.insert(file.lastPathComponent.lowercased()).inserted else { throw CocoaError(.fileWriteFileExists) }
            let copy = payload.appendingPathComponent(file.lastPathComponent)
            try manager.copyItem(at: file, to: copy)
            copies.append(copy)
        }
        let archive = directory.appendingPathComponent(name)
        try Zip.zipFiles(paths: copies, zipFilePath: archive, password: nil, progress: nil)
        try manager.removeItem(at: payload)
        succeeded = true
        return archive
    }

    /// 只删除本库创建的临时反馈目录，不删除调用方传入的资源。
    public static func remove(_ archive: URL) {
        let directory = archive.deletingLastPathComponent()
        guard directory.lastPathComponent.hasPrefix("quick_feedback_"),
              directory.deletingLastPathComponent().standardizedFileURL == FileManager.default.temporaryDirectory.standardizedFileURL else { return }
        try? FileManager.default.removeItem(at: directory)
    }
}
