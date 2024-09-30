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
        let title = subjectTitle ?? String(localized: "意见反馈",bundle: .module)
        let subject = "\(DeviceInfo.getAppName()) - \(title)"
        
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return encodedSubject
    }
    
    
    @MainActor static func deviceBaseInfo() -> String {
            return """
                    \(String(localized: "应用程序",bundle: .module)):\(DeviceInfo.getAppName())
                    \(String(localized: "应用版本",bundle: .module)):\(DeviceInfo.getAppVersion())
                    \(String(localized: "设备信息",bundle: .module)):\(DeviceInfo.getDeviceModel())
                    \(String(localized: "系统信息",bundle: .module)):\(DeviceInfo.getSystemVersion())
                            \n==========================================================\n
            """
        
    }
    
    static func geBody() -> String {
        //获取应用名和版本号
        var body = """
            \(String(localized: "应用程序",bundle: .module)):\(DeviceInfo.getAppName())
            \(String(localized: "应用版本",bundle: .module)):\(DeviceInfo.getAppVersion())
            \(String(localized: "设备信息",bundle: .module)):\(DeviceInfo.getDeviceModel())
            \(String(localized: "系统信息",bundle: .module)):\(DeviceInfo.getSystemVersion())
                    \n==========================================================\n
            \(String(localized: "反馈内容",bundle: .module)):\n
            
            \(String(localized: "反馈模块",bundle: .module)):"URL解析"
            
            Parmper:\n
            
            URL:\(url)
            
            
            """


        // 对subject和body进行URL编码，以处理空格和特殊字符
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        mailSender.sendMail(config: FeedbackMailConfig(email: "myhdify@gmail.com", subject: encodedSubject, body: encodedBody))
    }
}


