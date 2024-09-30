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
    
    static func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
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
