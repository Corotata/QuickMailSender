import SwiftUI

/// 调用方提供的已本地化文案，库不依赖具体应用或附件类型。
public struct FeedbackConfirmationConfiguration: Sendable {
    /// 弹窗标题。
    public let title: String
    /// 引导用户填写问题的说明。
    public let message: String
    /// 附件选项标题；没有附件说明时不显示选项。
    public let attachmentLabel: String
    /// 附件内容说明，为 nil 时仅确认普通反馈。
    public let attachmentDescription: String?
    /// 用户自行确认发送及取消附件的简短说明。
    public let footer: String?
    /// 取消按钮文案。
    public let cancelTitle: String
    /// 继续按钮文案。
    public let continueTitle: String
    /// 附件是否默认勾选。
    public let includesAttachmentsByDefault: Bool

    /// 用应用自己的文案创建确认配置，所有文字均由调用方本地化。
    public init(title: String, message: String, attachmentLabel: String = "",
                attachmentDescription: String? = nil, footer: String? = nil,
                cancelTitle: String, continueTitle: String, includesAttachmentsByDefault: Bool = true) {
        self.title = title
        self.message = message
        self.attachmentLabel = attachmentLabel
        self.attachmentDescription = attachmentDescription
        self.footer = footer
        self.cancelTitle = cancelTitle
        self.continueTitle = continueTitle
        self.includesAttachmentsByDefault = includesAttachmentsByDefault
    }
}

/// 通用反馈确认弹窗；回传附件选择，不读取文件，也不会自动发送邮件。
public struct FeedbackConfirmationView: View {
    /// 调用方配置的文案和默认选择。
    private let configuration: FeedbackConfirmationConfiguration
    /// 可选宿主主题色；未传入时使用宿主 accentColor。
    private let themeColor: Color?
    /// 用户确认后通知外部；外部应在弹窗关闭后打开邮件。
    private let onConfirm: (Bool) -> Void
    /// 当前附件选择，每次新建弹窗按配置初始化。
    @State private var includesAttachments: Bool
    /// 关闭当前弹窗。
    @Environment(\.dismiss) private var dismiss

    /// 创建可用于 sheet 的紧凑确认界面。
    public init(configuration: FeedbackConfirmationConfiguration, themeColor: Color? = nil, onConfirm: @escaping (Bool) -> Void) {
        self.configuration = configuration
        self.themeColor = themeColor
        self.onConfirm = onConfirm
        _includesAttachments = State(initialValue: configuration.includesAttachmentsByDefault)
    }

    /// 将可选主题色应用到主按钮和附件控件，保留原有文案及选择行为。
    public var body: some View {
        Group {
            if let themeColor {
                content.tint(themeColor)
            } else {
                content
            }
        }
#if os(macOS)
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
#else
        .presentationDetents([.height(configuration.attachmentDescription == nil ? 230 : 330), .large])
        .presentationDragIndicator(.visible)
#endif
    }

    /// Mac 随内容收紧；iOS 正文可滚动，操作按钮固定在底部安全区上方。
    private var content: some View {
#if os(macOS)
        VStack(alignment: .leading, spacing: 20) {
            explanation
            actions
        }
        .padding(24)
#else
        ScrollView {
            explanation
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 8)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            actions
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 8)
        }
#endif
    }

    /// 两个等宽按钮复用编辑页的尺寸规范，不再叠加系统按钮内边距。
    private var actions: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: { Text(configuration.cancelTitle) }
                .buttonStyle(FeedbackActionButtonStyle(isPrimary: false, themeColor: themeColor ?? .accentColor))
                .keyboardShortcut(.cancelAction)
            Button {
                onConfirm(configuration.attachmentDescription != nil && includesAttachments)
                dismiss()
            } label: { Text(configuration.continueTitle) }
                .buttonStyle(FeedbackActionButtonStyle(isPrimary: true, themeColor: themeColor ?? .accentColor))
                .keyboardShortcut(.defaultAction)
        }
    }

    /// 标题与问题引导形成重点，附件选项和小字号说明归为同一组。
    private var explanation: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text(configuration.title)
                    .font(.title2.weight(.semibold))
                Text(configuration.message)
                    .font(.callout)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let description = configuration.attachmentDescription {
                VStack(alignment: .leading, spacing: 10) {
                    // 保留各平台原生标签布局，不强制 Mac 与 iOS 的开关位置一致。
                    Toggle(configuration.attachmentLabel, isOn: $includesAttachments)
                        .font(.subheadline.weight(.medium))
                    HStack(alignment: .top, spacing: 0) {
                        Text(description)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                        // 说明行同样撑满卡片，两个平台保持左对齐和一致的内容宽度。
                        Spacer(minLength: 0)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            }
            if let footer = configuration.footer {
                Text(footer).font(.footnote).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

}

/// 沿用 TxtToEpub 编辑页的主、次按钮规范，避免系统控件叠加额外高度。
private struct FeedbackActionButtonStyle: ButtonStyle {
    /// 主按钮使用实色填充，次按钮使用浅底描边。
    let isPrimary: Bool
    /// 宿主传入的主题色，不绑定具体产品。
    let themeColor: Color
    /// 继承外部禁用状态，保持不可用按钮可辨识。
    @Environment(\.isEnabled) private var isEnabled

    /// 两个平台使用相同内边距、圆角和按下反馈，整个背景均可点按。
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isPrimary ? Color.white : themeColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isPrimary ? (isEnabled ? themeColor : Color.gray) : themeColor.opacity(0.06))
            .overlay {
                if !isPrimary {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeColor.opacity(0.28), lineWidth: 1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
