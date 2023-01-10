//
//  CarTubeApp.swift
//  CarTube
//
//  Created by Rory Madden on 22/12/22.
//

import SwiftUI

@main
struct CarTubeApp: App {
    init() {
        registerDefaults()
        
        if UserDefaults.standard.bool(forKey: "LockScreenDimmingOn") {
            registerForScreenOffNotification {
                CarPlaySingleton.shared.saveInitialBrightness()
                CarPlaySingleton.shared.showScreenOffWarning()
                CarPlaySingleton.shared.setLowBrightness()
            }
            registerForUnlockNotification {
                CarPlaySingleton.shared.restoreBrightness()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView().onOpenURL { url in
                let id = url.absoluteString.replacingOccurrences(of: "^cartube?://", with: "", options: .regularExpression)
                if id.count != 11 {
                    UIApplication.shared.alert(body: "Invalid YouTube link.", window: .main)
                } else {
                    let youtube = YT_EMBED + id
                    CarPlaySingleton.shared.loadUrl(youtube)
                }
            }.onAppear {
                checkNewVersions()
            }
        }
    }
    
    func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            "SponsorBlockOn": true,
            "Zoom": 80,
            "ScreenPersistenceOn": true,
            "LockScreenDimmingOn": true
        ])
    }
    
    func checkNewVersions() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, let url = URL(string: "https://api.github.com/repos/Avangelista/CarTube/releases/latest") {
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                guard let data = data else { return }
                
                if let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    if (json["tag_name"] as? String)?.compare(version, options: .numeric) == .orderedDescending {
                        UIApplication.shared.confirmAlert(title: "Update Available", body: "A new version of CarTube is available.\n\(json["body"] as? String ?? "Updating is recommended to avoid bugs.")\nWould you like to view the releases page?", onOK: {
                            UIApplication.shared.open(URL(string: "https://github.com/Avangelista/CarTube/releases/latest")!)
                        }, noCancel: false, window: .main)
                    }
                }
            }
            task.resume()
        }
    }
}
