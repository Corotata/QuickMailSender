//
//  SwiftUIView.swift
//  QuickMailSender
//
//  Created by Corotata on 2024/9/30.
//

import SwiftUI



struct ContentView: View {
    let sender = PlatformMailSender()
    
    var body: some View {
       
        Button("Send Email", action: {
            let module = DefaultFeedbackModule(moduleName: "聊天模块", errorInfo: "error:\(12312312312312)", requestParameters: ["key" : "Any"])
            let configure = FeedbackMailConfig.mailCOnfig(to: "corotata@qq.com", defaultFeedbackModule: module)
            sender.sendMail(config: configure)
        })
            .onAppear {
//                let subject = String.defaultSubject(nil)
                let module = DefaultFeedbackModule(moduleName: "聊天模块", errorInfo: "error:\(12312312312312)", requestParameters: ["key" : "Any"])
//                let body = String.generateEmailBody(feedbackModule: module)
//                
//               
//                print("subject:\n\(subject)")
//                
//                print("body:\n\(body)")
                let configure = FeedbackMailConfig.mailCOnfig(to: "corotata@qq.com", defaultFeedbackModule: module)
                print(configure)
                
            }
    }
}

#Preview {
    ContentView()
}
