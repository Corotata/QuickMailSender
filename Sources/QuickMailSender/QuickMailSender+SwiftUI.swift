//
//  QuickMailSender+SwiftUI.swift
//  QuickMailSender
//
//  SwiftUI 扩展 - 仅提供 Mac 平台的 popover 包装
//
//  Created by Kiro on 2025/6/11.
//

import SwiftUI

#if os(macOS)

// MARK: - Mac 平台专用扩展

public extension View {
    /// 添加反馈 popover（Mac 专用）
    ///
    /// 职责：
    /// - 简单包装 `FeedbackContactView` 的 popover 显示
    /// - 不管理状态、不控制延迟、不做平台适配
    ///
    /// 使用示例：
    /// ```swift
    /// @State private var showFeedback = false
    ///
    /// Button("去反馈") {
    ///     showFeedback = true
    /// }
    /// .macFeedbackPopover(
    ///     isPresented: $showFeedback,
    ///     feedbackType: AppFeedbackType.contactUs
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - isPresented: 控制 popover 显示的绑定状态
    ///   - feedbackType: 遵循 FeedbackTypeProtocol 的反馈类型
    ///
    /// - Returns: 添加了 popover 的 View
    func macFeedbackPopover<FeedbackType: FeedbackTypeProtocol>(
        isPresented: Binding<Bool>,
        feedbackType: FeedbackType
    ) -> some View {
        popover(isPresented: isPresented, arrowEdge: .top) {
            FeedbackContactView(
                isPresented: isPresented,
                feedbackType: feedbackType
            )
        }
    }
}

#endif
