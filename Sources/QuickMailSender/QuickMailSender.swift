
//
//  PlatformMailSender
//  Created by Corotata on 2024/9/30.
//

//import SwiftUI
//#if canImport(UIKit)
//import UIKit
//import MessageUI
//
//typealias PlatformViewController = UIViewController
//typealias PlatformApplication = UIApplication
//typealias MailComposeViewController = MFMailComposeViewController
//typealias MailComposeResult = MFMailComposeResult
//
//#elseif canImport(AppKit)
//import AppKit
//
//typealias PlatformViewController = NSViewController
//typealias PlatformApplication = NSWorkspace
//typealias MailComposeViewController = NSViewController
//typealias MailComposeResult = Int
//
//#endif
//
//// MARK: - 反馈邮件配置
//public struct FeedbackMailConfig : Sendable{
//    let email: String
//    let subject: String
//    let body: String
//    
//   public init(email: String, subject: String, body: String) {
//        self.email = email
//        self.subject = subject
//        self.body = body
//    }
//    
//    
//    @MainActor static func mailConfig(to email: String,
//                                       subject: String? = nil,
//                                       feedbackModule: FeedbackModule) -> FeedbackMailConfig {
//        let body = String.generateEmailBody(feedbackModule: feedbackModule)
//        var subject = subject ?? String.defaultSubject()
//        
//        return FeedbackMailConfig(email: email, subject: subject, body: body)
//    }
//    
//    @MainActor public static func mailConfig(to email: String,
//                                       subject: String? = nil,
//                                       defaultFeedbackModule: DefaultFeedbackModule) -> FeedbackMailConfig {
//        var subject = subject ?? String.defaultSubject()
//        let body = String.generateEmailBody(feedbackModule: defaultFeedbackModule)
//        
//        return FeedbackMailConfig(email: email, subject: subject, body: body)
//    }
//}
//
//// MARK: - 邮件发送协议
//protocol MailSender {
//    func sendMail(config: FeedbackMailConfig) async
//}
//
//#if canImport(UIKit)
//import UIKit
//
//
//// MARK: - 平台特定邮件发送器 (iOS)
//public class PlatformMailSender: NSObject, MailSender, @preconcurrency MFMailComposeViewControllerDelegate {
//    private weak var viewController: UIViewController?
//    
//    private var completion: ((Result<MailComposeResult, Error>) -> Void)?
//    
//    public override init() {
//        super.init()
//    }
//    
//    @MainActor
//    public func sendMail(config: FeedbackMailConfig) {
//        viewController = UIViewController.topMostViewController()
//        
//        if MFMailComposeViewController.canSendMail() {
//            let mailComposer = MailComposeViewController()
//            mailComposer.mailComposeDelegate = self
//            mailComposer.setToRecipients([config.email])
//            mailComposer.setSubject(config.subject)
//            mailComposer.setMessageBody(config.body, isHTML: false)
//            viewController?.present(mailComposer, animated: true)
//        } else {
//            openMailTo(config: config)
//        }
//    }
//    
//    @MainActor private func openMailTo(config: FeedbackMailConfig) {
//        let urlString = "mailto:\(config.email)?subject=\(config.subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(config.body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
//        if let url = URL(string: urlString) {
//            PlatformApplication.shared.open(url)
//        }
//    }
//   
//    @MainActor
//    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
//        controller.dismiss(animated: true) {
//            if let error = error {
//                self.completion?(.failure(error))
//            } else {
//                self.completion?(.success(result))
//            }
//        }
//    }
//}
//
//#elseif canImport(AppKit)
//
//// MARK: - 平台特定邮件发送器 (macOS)
//public class PlatformMailSender: NSObject, MailSender {
//    public func sendMail(config: FeedbackMailConfig) {
//        Task {
//            let urlString = "mailto:\(config.email)?subject=\(config.subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(config.body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
//            if let url = URL(string: urlString) {
//                await PlatformApplication.shared.open(url)
//            }
//        }
//    }
//}
//
//
//#endif
//
//
//// 定义反馈模块协议
//protocol FeedbackModule {
//    var moduleName: String { get }
//    var errorInfo: String? { get }
//    var requestParameters: [String: Any]? { get }
//}
//
//// 创建一个默认的反馈模块结构体
//public struct DefaultFeedbackModule: FeedbackModule {
//    public let moduleName: String
//    public let errorInfo: String?
//    public let requestParameters: [String: Any]?
//    
//    public init(moduleName: String, errorInfo: String? = nil, requestParameters: [String : Any]? = nil) {
//        self.moduleName = moduleName
//        self.errorInfo = errorInfo
//        self.requestParameters = requestParameters
//    }
//}
//
//
//
//extension String {
//    
//    /// 默认的标题
//    public static func defaultSubject(_ subjectTitle: String? = nil) -> String {
//        let title = subjectTitle ?? NSLocalizedString("意见反馈", bundle: .module, comment: "")
//        let subject = "\(DeviceInfo.getAppName()) - \(title)"
//        return subject
//    }
//    
//    /// 获取设备基本信息
//    @MainActor public static func deviceBaseInfo() -> String {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//        let currentDate = dateFormatter.string(from: Date())
//        
//        return """
//        \(NSLocalizedString("当前日期", bundle: .module, comment: "")): \(currentDate)
//        \(NSLocalizedString("应用名称", bundle: .module, comment: "")): \(DeviceInfo.getAppName())
//        \(NSLocalizedString("应用版本", bundle: .module, comment: "")): \(DeviceInfo.getAppVersion())
//        \(NSLocalizedString("设备型号", bundle: .module, comment: "")): \(DeviceInfo.getDeviceModel())
//        \(NSLocalizedString("操作系统", bundle: .module, comment: "")): \(DeviceInfo.getSystemVersion())
//        """
//    }
//    
//    /// 生成邮件正文
//    @MainActor static func generateEmailBody(feedbackModule: FeedbackModule) -> String {
//        var body = deviceBaseInfo()
//        body += "\n\n" + generateFeedbackModuleInfo(feedbackModule)
//        return body
//    }
//    
//    // 生成反馈模块信息的函数
//    static func generateFeedbackModuleInfo(_ module: FeedbackModule) -> String {
//        var info = "\(NSLocalizedString("内容模块", bundle: .module, comment: "")): \(module.moduleName)\n"
//        if let errorInfo = module.errorInfo {
//            info += "\(NSLocalizedString("错误信息", bundle: .module, comment: "")): \(errorInfo)\n"
//        }
//        if let parameters = module.requestParameters {
//            info += "\(NSLocalizedString("相关参数", bundle: .module, comment: "")):\n"
//            let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
//            if let jsonString = jsonData.flatMap({ String(data: $0, encoding: .utf8) }) {
//                info += jsonString
//            } else {
//                for (key, value) in parameters {
//                    info += "  \(key): \(value)\n"
//                }
//            }
//        }
//        
//        info += "\n\n\(NSLocalizedString("反馈内容", bundle: .module, comment: "")): \n\n\n\n"
//        
//        return info
//    }
//    
//}

import SwiftUI


// MARK: - 反馈邮件配置
public struct FeedbackMailConfig: Sendable {
    let email: String
    let subject: String
    let body: String
    
    public init(email: String, subject: String, body: String) {
        self.email = email
        self.subject = subject
        self.body = body
    }
    
    @MainActor
    public static func mailConfig(to email: String, subject: String? = nil, feedbackModule: FeedbackModule) -> FeedbackMailConfig {
        let body = String.generateEmailBody(feedbackModule: feedbackModule)
        let finalSubject = subject ?? String.defaultSubject()
        return FeedbackMailConfig(email: email, subject: finalSubject, body: body)
    }
}

// MARK: - 反馈模块协议
public protocol FeedbackModule {
    var moduleName: String { get }
    var errorInfo: String? { get }
    var requestParameters: [String: Any]? { get }
}

// MARK: - 默认反馈模块
public struct DefaultFeedbackModule: FeedbackModule {
    public let moduleName: String
    public let errorInfo: String?
    public let requestParameters: [String: Any]?
    
    public init(moduleName: String, errorInfo: String? = nil, requestParameters: [String : Any]? = nil) {
        self.moduleName = moduleName
        self.errorInfo = errorInfo
        self.requestParameters = requestParameters
    }
}

// MARK: - 邮件发送结果
public enum MailSendResult: Sendable {
    case sent
    case saved
    case cancelled
    case failed(Error?)
    
    public var description: String {
        switch self {
        case .sent:
            return NSLocalizedString("已提交，请稍后核对邮件是否发送成功。", bundle: .main, comment: "")
        case .saved:
           return NSLocalizedString("已保存", bundle: .main, comment: "")
        case .cancelled:
           return NSLocalizedString("已取消", bundle: .main, comment: "")
        case .failed(let error):
            return NSLocalizedString("发送失败：", bundle: .main, comment: "") + (error?.localizedDescription ?? "")
        }
    }
    
}

// MARK: - 邮件发送协议
public protocol MailSender: AnyObject {
    func sendMail(config: FeedbackMailConfig, completion: @escaping @Sendable (MailSendResult) -> Void)
}


// MARK: - 平台特定邮件发送器
#if canImport(UIKit)
import UIKit
import MessageUI

actor MailSenderActor {
    private weak var viewController: UIViewController?
    private var completion: (@Sendable (MailSendResult) -> Void)?
    
    func setViewController(_ viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func setCompletion(_ completion: @escaping @Sendable (MailSendResult) -> Void) {
        self.completion = completion
    }
    
    func getViewController() -> UIViewController? {
        return viewController
    }
    
    func callCompletion(with result: MailSendResult) {
        completion?(result)
    }
}

@MainActor
public class PlatformMailSender: NSObject, @preconcurrency MailSender, MFMailComposeViewControllerDelegate {
    private let mailActor = MailSenderActor()
    
    public override init() {
        super.init()
    }
    
    public func sendMail(config: FeedbackMailConfig, completion: @escaping @Sendable (MailSendResult) -> Void) {
        Task {
            await mailActor.setCompletion(completion)
            await mailActor.setViewController(UIViewController.topMostViewController()!)
            
            if MFMailComposeViewController.canSendMail() {
                let mailComposer = MFMailComposeViewController()
                mailComposer.mailComposeDelegate = self
                mailComposer.setToRecipients([config.email])
                mailComposer.setSubject(config.subject)
                mailComposer.setMessageBody(config.body, isHTML: false)
                await mailActor.getViewController()?.present(mailComposer, animated: true)
            } else {
                openMailTo(config: config)
            }
        }
    }
    
    private func openMailTo(config: FeedbackMailConfig) {
        let urlString = "mailto:\(config.email)?subject=\(config.subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(config.body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url) { [weak self] success in
                Task { [weak self] in
                    if success {
                        await self?.mailActor.callCompletion(with: .sent)
                    } else {
                        await self?.mailActor.callCompletion(with: .failed(nil))
                    }
                }
            }
        } else {
            Task { [weak self] in
                await self?.mailActor.callCompletion(with: .failed(nil))
            }
        }
    }
    
    nonisolated public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        Task { @MainActor [weak self] in
            controller.dismiss(animated: true) {
                Task { [weak self] in
                    switch result {
                    case .sent:
                        await self?.mailActor.callCompletion(with: .sent)
                    case .saved:
                        await self?.mailActor.callCompletion(with: .saved)
                    case .cancelled:
                        await self?.mailActor.callCompletion(with: .cancelled)
                    case .failed:
                        await self?.mailActor.callCompletion(with: .failed(error))
                    @unknown default:
                        await self?.mailActor.callCompletion(with: .failed(error))
                    }
                }
            }
        }
    }
}
#elseif canImport(AppKit)
import AppKit

public class PlatformMailSender: NSObject, MailSender {
    public func sendMail(config: FeedbackMailConfig, completion: @escaping @Sendable (MailSendResult) -> Void) {
        let urlString = "mailto:\(config.email)?subject=\(config.subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(config.body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let url = URL(string: urlString) {
            do {
                try NSWorkspace.shared.open(url)
            } catch {
                completion(.failed(error))
            }
        } else {
            completion(.failed(nil))
        }
    }
    
}
#endif

// MARK: - 字符串扩展
extension String {
    /// 默认的标题
    public static func defaultSubject(_ subjectTitle: String? = nil) -> String {
        let title = subjectTitle ?? NSLocalizedString("意见反馈", bundle: .module, comment: "")
        let subject = "\(DeviceInfo.getAppName()) - \(title)"
        return subject
    }
    
    /// 获取设备基本信息
    @MainActor public static func deviceBaseInfo() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDate = dateFormatter.string(from: Date())
        
        return """
        \(NSLocalizedString("当前日期", bundle: .module, comment: "")): \(currentDate)
        \(NSLocalizedString("应用名称", bundle: .module, comment: "")): \(DeviceInfo.getAppName())
        \(NSLocalizedString("应用版本", bundle: .module, comment: "")): \(DeviceInfo.getAppVersion())
        \(NSLocalizedString("设备型号", bundle: .module, comment: "")): \(DeviceInfo.getDeviceModel())
        \(NSLocalizedString("操作系统", bundle: .module, comment: "")): \(DeviceInfo.getSystemVersion())
        """
    }
    
    /// 生成邮件正文
    @MainActor static func generateEmailBody(feedbackModule: FeedbackModule) -> String {
        var body = deviceBaseInfo()
        body += "\n\n" + generateFeedbackModuleInfo(feedbackModule)
        return body
    }
    
    // 生成反馈模块信息的函数
    static func generateFeedbackModuleInfo(_ module: FeedbackModule) -> String {
        var info = "\(NSLocalizedString("内容模块", bundle: .module, comment: "")): \(module.moduleName)\n"
        if let errorInfo = module.errorInfo {
            info += "\(NSLocalizedString("错误信息", bundle: .module, comment: "")): \(errorInfo)\n"
        }
        if let parameters = module.requestParameters {
            info += "\(NSLocalizedString("相关参数", bundle: .module, comment: "")):\n"
            let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            if let jsonString = jsonData.flatMap({ String(data: $0, encoding: .utf8) }) {
                info += jsonString
            } else {
                for (key, value) in parameters {
                    info += "  \(key): \(value)\n"
                }
            }
        }
        
        info += "\n\n\(NSLocalizedString("反馈内容", bundle: .module, comment: "")): \n\n\n\n"
        
        return info
    }
}


