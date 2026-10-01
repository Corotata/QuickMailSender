#if os(macOS)
import Foundation
import Testing
@testable import QuickMailSender

/// 同名附件保留各自内容，名称中的路径不能逃出专属临时目录。
@Test func attachmentsPreserveDataAndSeparateDuplicateNames() throws {
    let first = Data([0, 1, 2, 255])
    let second = Data("译文 JSON".utf8)
    let files = try MacMailAttachments(attachments: [
        EmailAttachment(data: first, mimeType: "application/zip", fileName: "../诊断.zip"),
        EmailAttachment(data: second, mimeType: "application/zip", fileName: "诊断.zip")
    ])
    #expect(files.fileURLs.count == 2)
    #expect(files.fileURLs[0] != files.fileURLs[1])
    #expect(files.fileURLs.allSatisfy { $0.path.hasPrefix(files.directory.path + "/") })
    #expect(files.fileURLs[0].lastPathComponent == "诊断.zip")
    #expect(try Data(contentsOf: files.fileURLs[0]) == first)
    #expect(try Data(contentsOf: files.fileURLs[1]) == second)
    files.removeFiles()
    #expect(!FileManager.default.fileExists(atPath: files.directory.path))
    files.removeFiles()
}

/// 没有附件时仍允许创建普通反馈邮件；无效名称必须明确失败。
@Test func emptyAttachmentsAndInvalidName() throws {
    let empty = try MacMailAttachments(attachments: [])
    #expect(empty.fileURLs.isEmpty)
    #expect(throws: MacMailSharingError.self) {
        _ = try MacMailAttachments(attachments: [
            EmailAttachment(data: Data(), mimeType: "application/zip", fileName: "..")
        ])
    }
}
#endif
