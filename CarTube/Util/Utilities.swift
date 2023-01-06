//
//  Utilities.swift
//  CarTube
//
//  Created by Rory Madden on 5/1/2023.
//

import Foundation
import UIKit
import notify
import Dynamic

/// Check if the given string is a valid YouTube URL
func isYouTubeURL(_ url: String) -> Bool {
    return extractYouTubeVideoID(url) != nil
}

/// Given a URL string, extract the YouTube video ID
func extractYouTubeVideoID(_ url: String) -> String? {
    let regex = try! NSRegularExpression(pattern: "^(?:https?://)?(?:www\\.)?(?:m\\.|www\\.|)(?:youtu\\.be/|youtube\\.com/(?:embed/|v/|watch\\?v=|watch\\?.+&v=))((\\w|-){11})(?:\\S+)?$")
    guard let match = regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)) else { return nil }
    guard let range = Range(match.range(at: 1), in: url) else { return nil }
    return String(url[range])
}

/// Minimise the app and close it
func exitGracefully() {
    UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
        exit(0)
    }
}

/// Register a specified function to be run when the screen locks
func registerForLockNotification(callback: @escaping () -> Void) {
    var notify_token: Int32 = 0
    notify_register_dispatch("com.apple.springboard.lockstate", &notify_token, DispatchQueue.main, { token in
        var state: Int64 = 0
        notify_get_state(token, &state)
        let deviceLocked = state == 1
        let brightness = getScreenBrightness()
        if deviceLocked && brightness == 0 {
//        if deviceLocked {
            callback()
        }
    })
}

/// Register a specified function to be run when the screen unlocks
func registerForUnlockNotification(callback: @escaping () -> Void) {
    var notify_token: Int32 = 0
    notify_register_dispatch("com.apple.springboard.lockstate", &notify_token, DispatchQueue.main, { token in
        var state: Int64 = 0
        notify_get_state(token, &state)
        let deviceUnlocked = state == 0
        if deviceUnlocked {
            callback()
        }
    })
}

/// Check if the screen is currently locked - also fires on notification screen
func isScreenLocked() -> Bool {
    let sbs = dlopen("/System/Library/PrivateFrameworks/SpringBoardServices.framework/SpringBoardServices", RTLD_LAZY)
    defer {
        dlclose(sbs)
    }

    let s1 = dlsym(sbs, "SBSSpringBoardServerPort")
    let SBSSpringBoardServerPort = unsafeBitCast(s1, to: (@convention(c) () -> mach_port_t).self)

    let s2 = dlsym(sbs, "SBGetScreenLockStatus")
    var lockStatus: ObjCBool = false
    var passcodeEnabled: ObjCBool = false
    let SBGetScreenLockStatus = unsafeBitCast(s2, to: (@convention(c) (mach_port_t, UnsafeMutablePointer<ObjCBool>, UnsafeMutablePointer<ObjCBool>) -> Void).self)
    SBGetScreenLockStatus(SBSSpringBoardServerPort(), &lockStatus, &passcodeEnabled)
    return lockStatus.boolValue
}

/// Get the current display brightness, is 0 if off
func getScreenBrightness() -> Float {
    let bbs = dlopen("/System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices", RTLD_LAZY)
    defer {
        dlclose(bbs)
    }
    
    let s = dlsym(bbs, "BKSDisplayBrightnessGetCurrent")
    let BKSDisplayBrightnessGetCurrent = unsafeBitCast(s, to: (@convention(c) () -> Float).self)
    let brightness = BKSDisplayBrightnessGetCurrent()
    
    return brightness
}

/// Set the current display brightness
/// Requires entitlement "com.apple.backboard.displaybrightness"
func setScreenBrightness(_ brightness: Float) {
    guard brightness >= 0, brightness <= 1 else { return }
    let bbs = dlopen("/System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices", RTLD_LAZY)
    defer {
        dlclose(bbs)
    }
    
    let s = dlsym(bbs, "BKSDisplayBrightnessSet")
    let BKSDisplayBrightnessSet = unsafeBitCast(s, to: (@convention(c) (Float, NSInteger) -> Void).self)
    BKSDisplayBrightnessSet(brightness, 1)
}

/// Check if auto-brightness is enabled
/// Requires entitlements "platform-application", "com.apple.private.security.no-container"
func isAutoBrightnessEnabled() -> Bool {
    let autoBrightnessKey = "BKEnableALS" as CFString
    let backboardd = "com.apple.backboardd" as CFString
    var keyExists: DarwinBoolean = false
    let enabled = CFPreferencesGetAppBooleanValue(autoBrightnessKey, backboardd, &keyExists)
    if keyExists.boolValue {
        return enabled
    }
    return false
}

/// Retrieve brightness from settings, as this will return the saved value even with the screen off
/// Requires entitlements "platform-application", "com.apple.private.security.no-container"
func getSettingsBrightness() -> Float {
    let brightnessKey1 = "SBBacklightLevel" as CFString
    let brightnessKey2 = "SBBacklightLevel2" as CFString
    let springboard = "com.apple.springboard" as CFString
    if let brightness1 = CFPreferencesCopyAppValue(brightnessKey1, springboard) as? Float {
        return brightness1
    } else if let brightness2 = CFPreferencesCopyAppValue(brightnessKey2, springboard) as? Float {
        return brightness2
    }
    return 0
}

/// Enable or disable auto-brightness
/// Requires entitlement "com.apple.backboard.displaybrightness"
func setAutoBrightness(_ on: Bool) {
    let bbs = dlopen("/System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices", RTLD_LAZY)
    defer {
        dlclose(bbs)
    }
    
    let s = dlsym(bbs, "BKSDisplayBrightnessSetAutoBrightnessEnabled")
    let BKSDisplayBrightnessSetAutoBrightnessEnabled = unsafeBitCast(s, to: (@convention(c) (ObjCBool) -> Void).self)
    BKSDisplayBrightnessSetAutoBrightnessEnabled(ObjCBool(on))
}

/// Get information on the currently playing song
func getNowPlaying(completion: @escaping (Result<(title: String, artist: String, bundleID: String), Error>) -> Void) {
    let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))

    guard let MRMediaRemoteGetNowPlayingInfoPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString) else {
        completion(.failure("Error"))
        return
    }
    typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
    let MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(MRMediaRemoteGetNowPlayingInfoPointer, to: MRMediaRemoteGetNowPlayingInfoFunction.self)

    MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main, { (information) in
        let bundleInfo = Dynamic._MRNowPlayingClientProtobuf.initWithData(information["kMRMediaRemoteNowPlayingInfoClientPropertiesData"])
        guard let title = information["kMRMediaRemoteNowPlayingInfoTitle"] as? String else {
            completion(.failure("Error getting title"))
            return
        }
        guard let artist = information["kMRMediaRemoteNowPlayingInfoArtist"] as? String else {
            completion(.failure("Error getting artist"))
            return
        }
        guard let bundleID = bundleInfo.bundleIdentifier.asString else {
            completion(.failure("Error getting bundle ID"))
            return
        }
        completion(.success((title, artist, bundleID)))
    })
}
