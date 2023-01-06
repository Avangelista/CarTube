//
//  Settings.swift
//  CarTube
//
//  Created by Rory Madden on 5/1/2023.
//

import SwiftUI

struct Settings: View {
    @State private var screenPersistenceOn = UserDefaults.standard.bool(forKey: "ScreenPersistenceOn")
    @State private var lockScreenDimmingOn = UserDefaults.standard.bool(forKey: "LockScreenDimmingOn")
    @State private var zoom = UserDefaults.standard.integer(forKey: "Zoom")
    @State private var sponsorBlockOn = UserDefaults.standard.bool(forKey: "SponsorBlockOn")
    
    func saveSettings() {
        UserDefaults.standard.set(sponsorBlockOn, forKey: "SponsorBlockOn")
        UserDefaults.standard.set(zoom, forKey: "Zoom")
        UserDefaults.standard.set(screenPersistenceOn, forKey: "ScreenPersistenceOn")
        UserDefaults.standard.set(lockScreenDimmingOn, forKey: "LockScreenDimmingOn")
        exitGracefully()
    }
    
    var body: some View {
        Form {
            List {
                Section(footer: Text("Set the zoom level for the YouTube UI.")) {
                    Incrementer(value: $zoom)
                }
                Section(footer: Text("Block sponsored segments in videos.")) {
                    Toggle(isOn: $sponsorBlockOn) {
                        Text("SponsorBlock")
                    }
                }
                Section(footer: Text("RECOMMENDED.\nCarTube requires the phone screen to be on at all times.\nThe Screen Persistence Helper will keep the phone screen on, even on the Lock Screen.\nShorts will not work with this enabled.")) {
                    Toggle(isOn: $screenPersistenceOn) {
                        Text("Screen Persistence Helper")
                    }
                }
                Section(footer: Text("RECOMMENDED.\nDim the Lock Screen while the app is running.")) {
                    Toggle(isOn: $lockScreenDimmingOn) {
                        Text("Lock Screen Dimming")
                    }
                }
                Section(footer: Text("The app will quit.")) {
                    Button("Save Settings") {
                        saveSettings()
                    }
                }
            }
        }.navigationBarTitle("Settings", displayMode: .inline)
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        Settings()
    }
}
