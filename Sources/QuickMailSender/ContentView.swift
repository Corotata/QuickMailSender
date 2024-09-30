//
//  SwiftUIView.swift
//  QuickMailSender
//
//  Created by Corotata on 2024/9/30.
//

import SwiftUI



struct ContentView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            .onAppear {
                let subject = String.defaultSubject("意见反馈")
                let module = DefaultFeedbackModule(moduleName: "聊天模块", errorInfo: "error:\(12312312312312)", requestParameters: ["key" : "Any"])
                let body = String.generateEmailBody(feedbackContent: "123123123", feedbackModule: module)
                
                
                print("subject:\n\(subject)")
                
                print("body:\n\(body)")
                
            }
    }
}

#Preview {
    ContentView()
}
