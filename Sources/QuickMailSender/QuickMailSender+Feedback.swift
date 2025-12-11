//
//  QuickMailSender+Feedback.swift
//  QuickMailSender
//
//  Created by Corotata on 2024/12/11.
//
//  通用反馈系统扩展
//  提供了一套完整的反馈框架，支持任何项目快速集成反馈功能
//

import Foundation

/// 通用反馈框架 - 可被任何项目复用
/// 使用方式：
/// 1. 定义自己的反馈类型枚举，遵循 FeedbackTypeProtocol
/// 2. 实现必要的属性和方法
/// 3. 使用 QuickMailSender.default.sendFeedback(_:) 发送反馈

// MARK: - 反馈类型协议

/// 反馈类型必须遵循的协议
public protocol FeedbackTypeProtocol {
    /// 反馈模块名称（用于邮件正文）
    var moduleName: String { get }
    
    /// 邮件主题（不包含应用名称，会自动添加）
    var mailSubject: String { get }
    
    /// 反馈参数（用于邮件正文中的"相关参数"部分）
    var feedbackParameters: [String: String] { get }
    
    
    static var feedbackEmail: String { get }
}




extension FeedbackTypeProtocol {
    @MainActor
    public func sendFeedback(
        additionalInfo: String? = nil,
        completion: @escaping @Sendable (MailSendResult) -> Void
    ) {
        var parameters = feedbackParameters
        if let additionalInfo = additionalInfo {
            parameters["userMessage"] = additionalInfo
        }
        
        let feedbackModule = DefaultFeedbackModule(
            moduleName: moduleName,
            requestParameters: parameters
        )
        
        let finalSubject = String.defaultSubject(mailSubject)
        
        QuickMailSender.default.sendMail(
            to: Self.feedbackEmail,
            subject: finalSubject,
            feedbackModule: feedbackModule,
            completion: completion
        )
    }
}

// MARK: - QuickMailSender 反馈扩展

public extension QuickMailSender {
    /// 通用反馈发送方法 - 支持任何遵循 FeedbackTypeProtocol 的反馈类型
    ///
    /// 这是一个通用的反馈发送方法，支持任何项目的反馈类型。
    /// 项目只需要定义自己的反馈类型和配置，就可以使用此方法发送反馈。
    ///
    /// - Parameters:
    ///   - feedbackType: 反馈类型（遵循 FeedbackTypeProtocol）
    ///   - config: 反馈配置（遵循 FeedbackConfigProtocol）
    ///   - additionalInfo: 额外信息（用户输入的描述）
    ///   - completion: 完成回调
    ///
    /// - Example:
    /// ```swift
    /// // 定义反馈类型
    /// enum MyAppFeedbackType: FeedbackTypeProtocol {
    ///     case webExtraction(url: String?, error: String?)
    ///     case contactUs
    ///
    ///     static let feedbackEmail = "support@myapp.com"
    ///
    ///     var moduleName: String {
    ///         switch self {
    ///         case .webExtraction:
    ///             return "网页提取反馈"
    ///         case .contactUs:
    ///             return "联系我们"
    ///         }
    ///     }
    ///
    ///     var mailSubject: String {
    ///         switch self {
    ///         case .webExtraction:
    ///             return "网页提取反馈"
    ///         case .contactUs:
    ///             return "用户反馈"
    ///         }
    ///     }
    ///
    ///     var feedbackParameters: [String: String] {
    ///         var params: [String: String] = [:]
    ///         switch self {
    ///         case .webExtraction(let url, let error):
    ///             if let url = url { params["url"] = url }
    ///             if let error = error { params["error"] = error }
    ///         case .contactUs:
    ///             break
    ///         }
    ///         return params
    ///     }
    /// }
    ///
    /// // 使用反馈系统（通过协议扩展的默认实现）
    /// MyAppFeedbackType.contactUs.sendFeedback { result in
    ///     print("反馈结果: \(result.description)")
    /// }
    /// ```
}
