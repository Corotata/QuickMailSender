import Foundation
import Testing
import Zip
@testable import QuickMailSender

/// 多个明确资源应完整进入 ZIP，打包失败或清理不会影响源文件。
@Test func feedbackArchivePreservesFilesAndCleansTemporaryCopy() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let book = root.appendingPathComponent("原书.epub")
    let json = root.appendingPathComponent("translations.json")
    try Data([0, 1, 255]).write(to: book)
    try Data("{\"translation\":\"译文\"}".utf8).write(to: json)
    let archive = try await FeedbackArchive.prepare(files: [book, json])
    let output = root.appendingPathComponent("extracted")
    try Zip.unzipFile(archive, destination: output, overwrite: true, password: nil)
    #expect(try Data(contentsOf: output.appendingPathComponent(book.lastPathComponent)) == Data(contentsOf: book))
    #expect(try Data(contentsOf: output.appendingPathComponent(json.lastPathComponent)) == Data(contentsOf: json))
    FeedbackArchive.remove(archive)
    #expect(!FileManager.default.fileExists(atPath: archive.deletingLastPathComponent().path))
    #expect(FileManager.default.fileExists(atPath: book.path))
    #expect(FileManager.default.fileExists(atPath: json.path))
}

/// 重名、目录和无效 ZIP 名称必须明确失败，不能悄悄丢失或扩大附件范围。
@Test func feedbackArchiveRejectsAmbiguousAndUnrequestedResources() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let first = root.appendingPathComponent("a")
    let second = root.appendingPathComponent("b")
    try FileManager.default.createDirectory(at: first, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: second, withIntermediateDirectories: true)
    let one = first.appendingPathComponent("same.txt")
    let two = second.appendingPathComponent("same.txt")
    try Data("one".utf8).write(to: one)
    try Data("two".utf8).write(to: two)
    #expect(throws: (any Error).self) { try FeedbackArchive.create(files: [one, two], temporaryRoot: root) }
    #expect(throws: (any Error).self) { try FeedbackArchive.create(files: [first], temporaryRoot: root) }
    #expect(throws: (any Error).self) { try FeedbackArchive.create(files: [one], archiveName: "../escape.zip", temporaryRoot: root) }
    #expect(throws: (any Error).self) { try FeedbackArchive.create(files: [], temporaryRoot: root) }
    let entries = try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
    #expect(Set(entries.map(\.lastPathComponent)) == ["a", "b"])
    // 清理入口拒绝源文件路径。
    FeedbackArchive.remove(one)
    #expect(try String(contentsOf: one, encoding: .utf8) == "one")
}
