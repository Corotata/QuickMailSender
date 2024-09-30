// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
#if canImport(UIKit)
import UIKit
import MessageUI

typealias PlatformViewController = UIViewController
typealias PlatformApplication = UIApplication
typealias MailComposeViewController = MFMailComposeViewController
typealias MailComposeResult = MFMailComposeResult

#elseif canImport(AppKit)
import AppKit

typealias PlatformViewController = NSViewController
typealias PlatformApplication = NSWorkspace
typealias MailComposeViewController = NSViewController
typealias MailComposeResult = Int

#endif

// MARK: - 反馈邮件配置
public struct FeedbackMailConfig : Sendable{
    let email: String
    let subject: String
    let body: String
    
   public init(email: String, subject: String, body: String) {
        self.email = email
        self.subject = subject
        self.body = body
    }
    
    
    @MainActor static func mailConfig(to email: String,
                                       subject: String? = nil,
                                       feedbackModule: FeedbackModule) -> FeedbackMailConfig {
        let body = String.generateEmailBody(feedbackModule: feedbackModule)
        var subject = subject ?? String.defaultSubject()
        
        return FeedbackMailConfig(email: email, subject: subject, body: body)
    }
    
    @MainActor public static func mailConfig(to email: String,
                                       subject: String? = nil,
                                       defaultFeedbackModule: DefaultFeedbackModule) -> FeedbackMailConfig {
        var subject = subject ?? String.defaultSubject()
        let body = String.generateEmailBody(feedbackModule: defaultFeedbackModule)
        
        return FeedbackMailConfig(email: email, subject: subject, body: body)
    }
    
    
    static let imageExtractor = FeedbackMailConfig(
        email: "myhdify@gmail.com",
        subject: "图片提取功能反馈",
        body: "请在此处描述您的反馈或建议：\n\n"
    )
}

// MARK: - 邮件发送协议
@available(iOS 15.0, macOS 13.0, *)
protocol MailSender {
    func sendMail(config: FeedbackMailConfig) async
}

#if canImport(UIKit)
import UIKit


// MARK: - 平台特定邮件发送器 (iOS)
@available(iOS 15.0, *)
public class PlatformMailSender: NSObject, MailSender, @preconcurrency MFMailComposeViewControllerDelegate {
    private weak var viewController: UIViewController?
    
    private var completion: ((Result<MailComposeResult, Error>) -> Void)?
    
    public override init() {
        super.init()
    }
    
    @MainActor
    public func sendMail(config: FeedbackMailConfig) {
        viewController = UIViewController.topMostViewController()
        
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients([config.email])
            mailComposer.setSubject(config.subject)
            mailComposer.setMessageBody(config.body, isHTML: false)
            viewController?.present(mailComposer, animated: true)
        } else {
            openMailTo(config: config)
        }
    }
    
    @MainActor private func openMailTo(config: FeedbackMailConfig) {
        let urlString = "mailto:\(config.email)?subject=\(config.subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(config.body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let url = URL(string: urlString) {
            PlatformApplication.shared.open(url)
        }
    }
   
    @MainActor
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true) {
            if let error = error {
                self.completion?(.failure(error))
            } else {
                self.completion?(.success(result))
            }
        }
    }
}

#elseif canImport(AppKit)

// MARK: - 平台特定邮件发送器 (macOS)
@available(macOS 13.0, *)
public class PlatformMailSender: NSObject, MailSender {
    public func sendMail(config: FeedbackMailConfig) {
        Task {
            let urlString = "mailto:\(config.email)?subject=\(config.subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(config.body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            if let url = URL(string: urlString) {
                await PlatformApplication.shared.open(url)
            }
        }
    }
}


#endif


// 定义反馈模块协议
protocol FeedbackModule {
    var moduleName: String { get }
    var errorInfo: String? { get }
    var requestParameters: [String: Any]? { get }
}

// 创建一个默认的反馈模块结构体
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

