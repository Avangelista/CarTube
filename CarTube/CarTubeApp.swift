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
    }

    var body: some Scene {
        WindowGroup {
            ContentView().onOpenURL { (url) in
                if !CarPlaySingleton.shared.isCarPlayConnected() {
                    UIApplication.shared.alert(body: "Phone is not connected to CarPlay.")
                } else {
                    let id = url.absoluteString.replacingOccurrences(of: "^cartube?://", with: "", options: .regularExpression)
                    if id.count != 11 {
                        UIApplication.shared.alert(body: "Invalid YouTube link.")
                    } else {
                        let youtube = "https://www.youtube.com/embed/" + id + "?controls=0"
                        CarPlaySingleton.shared.loadUrlString(urlString: youtube)
                    }
                }
            }
        }
    }
    
    func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            "SponsorBlockOn": true,
            "AdBlockerOn": true
        ])
    }
}
