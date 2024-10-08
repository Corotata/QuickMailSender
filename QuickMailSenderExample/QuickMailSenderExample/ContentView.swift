//
//  ContentView.swift
//  QuickMailSenderExample
//
//  Created by Corotata on 2024/9/30.
//


import SwiftUI
import QuickMailSender

@available(iOS 15.0, macOS 13.0, *)
public struct FeedbackView: View {
    @State private var recipientEmail = "support@example.com"
    @State private var subject = "应用反馈"
    @State private var mainName = "通用"
    @State private var errorInfo = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private let sender = QuickMailSender()
    
    public var body: some View {
        Form {
            Section(header: Text("邮件设置")) {
                TextField("收件人邮箱", text: $recipientEmail)
                TextField("主题", text: $subject)
            }
            
            Section(header: Text("反馈信息")) {
                TextField("模块名称", text: $mainName)
                TextField("错误信息 (可选)", text: $errorInfo)
            }
            
            Section {
                Button("发送反馈") {
                    sendFeedback()
                }
            }
        }
#if canImport(AppKit)
        .padding()
#endif
        .alert("提示", isPresented: $showAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func sendFeedback() {
        let main = DefaultFeedbackModule(
            moduleName: mainName,
            errorInfo: errorInfo.isEmpty ? nil : errorInfo,
            requestParameters: ["timestamp": Date().timeIntervalSince1970]
        )
        
        let config = FeedbackMailConfig.mailConfig(
            to: recipientEmail,
            subject: subject.isEmpty ? nil : subject,
            feedbackModule: main
        )
        
        sender.sendMail(config: config) { result in
            DispatchQueue.main.async {
                showAlert(message: result.description)
            }
        }
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}

@available(iOS 15.0, macOS 13.0, *)
struct ContentView: View {
    var body: some View {
        #if canImport(AppKit)
        FeedbackView()
            .navigationTitle("反馈")
        #else
        NavigationView {
            FeedbackView()
                .navigationTitle("反馈")
        }
        #endif
    }
}

#Preview {
    ContentView()
}
