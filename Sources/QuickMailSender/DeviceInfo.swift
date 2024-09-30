//
//  File.swift
//  QuickMailSender
//
//  Created by Corotata on 2024/9/30.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

struct DeviceInfo {
    static func getAppName() -> String {
        return Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? "Unknown"
    }
    
    static func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }
    
    @MainActor static func getDeviceModel() -> String {
            #if os(macOS)
            // 获取 Mac 设备型号
            var size: Int = 0
            sysctlbyname("hw.model", nil, &size, nil, 0)
            var model = [CChar](repeating: 0, count: size)
            sysctlbyname("hw.model", &model, &size, nil, 0)
            return String(cString: model)
            #else
        return UIDevice.modelName
            #endif
        }
        
        
    
    @MainActor static func getSystemVersion() -> String {
        #if os(iOS)
        return UIDevice.current.systemVersion
        #elseif os(macOS)
        return ProcessInfo.processInfo.operatingSystemVersionString
        #else
        return "Unknown"
        #endif
    }
    
    @MainActor static func getDeviceIdentifier() -> String {
        #if os(iOS)
        return UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
        #elseif os(macOS)
        return (try? Data(contentsOf: URL(fileURLWithPath: "/Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist")))?.base64EncodedString() ?? "Unknown"
        #else
        return "Unknown"
        #endif
    }
}
