// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI
#if canImport(UIKit)
import UIKit
import MessageUI

public typealias PlatformViewController = UIViewController
public typealias PlatformApplication = UIApplication
public typealias MailComposeViewController = MFMailComposeViewController
public typealias MailComposeResult = MFMailComposeResult

#elseif canImport(AppKit)
import AppKit

public typealias PlatformViewController = NSViewController
public typealias PlatformApplication = NSWorkspace
public typealias MailComposeViewController = NSViewController
public typealias MailComposeResult = Int

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
    static let imageExtractor = FeedbackMailConfig(
        email: "myhdify@gmail.com",
        subject: "图片提取功能反馈",
        body: "请在此处描述您的反馈或建议：\n\n"
    )
}

// MARK: - 邮件发送协议
protocol MailSender {
    func sendMail(config: FeedbackMailConfig) async
}

#if canImport(UIKit)
import UIKit


// MARK: - 平台特定邮件发送器
public class PlatformMailSender: NSObject, MailSender {
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
   
}

extension PlatformMailSender: @preconcurrency MFMailComposeViewControllerDelegate {
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

public class PlatformMailSender: NSObject, MailSender {
    public func sendMail(config: FeedbackMailConfig) {
        let urlString = "mailto:\(config.email)?subject=\(config.subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(config.body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let url = URL(string: urlString) {
            PlatformApplication.shared.open(url)
        }
    }
}


#endif


extension String {
    
    /// 默认的标题
    static func defaultSubject(_ subjectTitle: String?) -> String {
        let title = subjectTitle ?? NSLocalizedString("意见反馈", bundle: .module, comment: "")
        let subject = "\(DeviceInfo.getAppName()) - \(title)"
        
        return subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
    }
    
    /// 获取设备基本信息
    @MainActor static func deviceBaseInfo() -> String {
        return """
        \(NSLocalizedString("应用程序", bundle: .module, comment: "")):\(DeviceInfo.getAppName())
        \(NSLocalizedString("应用版本", bundle: .module, comment: "")):\(DeviceInfo.getAppVersion())
        \(NSLocalizedString("设备信息", bundle: .module, comment: "")):\(DeviceInfo.getDeviceModel())
        \(NSLocalizedString("系统信息", bundle: .module, comment: "")):\(DeviceInfo.getSystemVersion())
        \n==========================================================\n
        """
    }
    
    /// 生成邮件正文
    static func generateEmailBody(feedbackContent: String, feedbackModule: String, url: String?) -> String {
        var body = deviceBaseInfo()
        
        // 定义反馈模块协议
        protocol FeedbackModule {
            var moduleName: String { get }
            var errorInfo: String? { get }
            var requestParameters: [String: Any]? { get }
        }

        // 创建一个默认的反馈模块结构体
        struct DefaultFeedbackModule: FeedbackModule {
            let moduleName: String
            let errorInfo: String?
            let requestParameters: [String: Any]?
        }

        // 生成反馈模块信息的函数
        func generateFeedbackModuleInfo(_ module: FeedbackModule) -> String {
            var info = "\(NSLocalizedString("反馈模块", bundle: .module, comment: "")): \(module.moduleName)\n"
            if let errorInfo = module.errorInfo {
                info += "\(NSLocalizedString("错误信息", bundle: .module, comment: "")): \(errorInfo)\n"
            }
            if let parameters = module.requestParameters {
                info += "\(NSLocalizedString("请求参数", bundle: .module, comment: "")):\n"
                for (key, value) in parameters {
                    info += "  \(key): \(value)\n"
                }
            }
            return info
        }

        // 使用新的反馈模块信息生成邮件正文
        body += """
        \(NSLocalizedString("反馈内容", bundle: .module, comment: "")):\n
        \(feedbackContent)

        \(generateFeedbackModuleInfo(feedbackModule))
        """
        
        \(NSLocalizedString("反馈模块", bundle: .module, comment: "")):\(feedbackModule)
        
        """
        
        if let url = url {
            body += """
            
            URL: \(url)
            """
        }
        
        return body
    }
}

struct FeedbackMailComposer {
    static func composeMail(to email: String, subject: String?, feedbackContent: String, feedbackModule: String, url: String?) -> FeedbackMailConfig {
        let subject = String.defaultSubject(subject)
        let body = String.generateEmailBody(feedbackContent: feedbackContent, feedbackModule: feedbackModule, url: url)
        
        return FeedbackMailConfig(email: email, subject: subject, body: body)
    }
}


