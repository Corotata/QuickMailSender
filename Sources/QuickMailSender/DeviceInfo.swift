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
    /// 获取应用名称
    static func getAppName() -> String {
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        return appName ?? "Unknown App"
    }

    /// 获取应用版本号
    static func getAppVersion() -> String {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return appVersion ?? "Unknown Version"
    }

    /// 获取应用系统版本号
    static func getSystemVersion() -> String {
        let systemVersion = ProcessInfo.processInfo.operatingSystemVersion
        return "\(getPlatformName()) \(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)"
    }

    /// 获取平台数据
    static func getPlatformName() -> String {
        #if os(macOS)
        return "macOS"
        #elseif os(iOS)
        return "iOS"
        #elseif os(tvOS)
        return "tvOS"
        #elseif os(watchOS)
        return "watchOS"
        #else
        return "Unknown OS"
        #endif
    }

    /// 获取设备号
    @MainActor static func getDeviceModel() -> String {
        #if os(macOS)
        var size: Int = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
        #else
        return UIDevice.current.model
        #endif
    }
}
