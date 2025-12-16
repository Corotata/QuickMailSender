import SwiftUI

#if canImport(AppKit)
/// 通用反馈联系视图 - 支持任何遵循 FeedbackTypeProtocol 的反馈类型
public struct FeedbackContactView<FeedbackType: FeedbackTypeProtocol>: View {
    @Binding var isPresented: Bool
    let feedbackType: FeedbackType
    
    private var email: String { FeedbackType.feedbackEmail }
    private var subject: String { String.defaultSubject(feedbackType.mailSubject) }
    private var bodyText: String {
        let module = DefaultFeedbackModule(
            moduleName: feedbackType.moduleName,
            errorInfo: nil,
            requestParameters: feedbackType.feedbackParameters.isEmpty ? nil : feedbackType.feedbackParameters
        )
        return String.generateEmailBody(feedbackModule: module)
    }
    
    public init(isPresented: Binding<Bool>, feedbackType: FeedbackType) {
        self._isPresented = isPresented
        self.feedbackType = feedbackType
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(feedbackType.moduleName)
                    .font(.headline)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
            
            Text("如果有任何问题或建议，欢迎发送邮件。若自动跳转失败，请手动复制以下信息。")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Email Field
            CopyField(label: String(localized:"收件人",bundle: .module), content: email)
            
            // Subject Field
            CopyField(label: String(localized:"邮件主题",bundle: .module), content: subject)
            
            // Body Field
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("邮件正文 (包含设备信息)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("复制全部") {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(bodyText, forType: .string)
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
                
                TextEditor(text: .constant(bodyText))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .frame(height: 100)
                    .scrollContentBackground(.hidden)  // 隐藏默认背景
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(6)
            }
            
            HStack {
                Button("尝试自动转跳邮件") {
                    feedbackType.sendFeedback { _ in }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(width: 320)
    }
}

/// 复制字段组件
struct CopyField: View {
    let label: String
    let content: String
    @State private var isCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack {
                Text(content)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer()
                
                Button(action: {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(content, forType: .string)
                    
                    withAnimation { isCopied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { isCopied = false }
                    }
                }) {
                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(isCopied ? .green : .accentColor)
                }
                .buttonStyle(.plain)
            }
            .padding(10)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var isPresented = true
        
        var body: some View {
            if isPresented {
                FeedbackContactView(isPresented: $isPresented, feedbackType: PreviewFeedbackType.contactUs)
            }
        }
    }
    
    enum PreviewFeedbackType: FeedbackTypeProtocol {
        case contactUs
        
        static let feedbackEmail = "test@example.com"
        
        var moduleName: String { "联系我们" }
        var mailSubject: String { "用户反馈" }
        var feedbackParameters: [String: String] { [:] }
    }
    
    return PreviewWrapper()
}

#endif
