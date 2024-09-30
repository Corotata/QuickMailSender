//
//  ContentView.swift
//  QuickMailSenderExample
//
//  Created by Corotata on 2024/9/30.
//

import SwiftUI
import QuickMailSender

struct ContentView: View {
    let sender = PlatformMailSender()
    
    var body: some View {
       
        Button("Send Email", action: {
            let module = DefaultFeedbackModule(moduleName: "聊天模块", errorInfo: "error:\(12312312312312)", requestParameters: ["key" : "Any"])
            let configure = FeedbackMailConfig.mailConfig(to: "corotata@qq.com", defaultFeedbackModule: module)
            sender.sendMail(config: configure)
        })
    }
}

#Preview {
    ContentView()
}

#Preview {
    ContentView()
}
