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
    @State private var ageRestrictBypassOn = UserDefaults.standard.bool(forKey: "AgeRestrictBypassOn")
    @State private var adBlockerOn = UserDefaults.standard.bool(forKey: "AdBlockerOn")
    
    func saveSettings() {
        UserDefaults.standard.set(sponsorBlockOn, forKey: "SponsorBlockOn")
        UserDefaults.standard.set(ageRestrictBypassOn, forKey: "AgeRestrictBypassOn")
        UserDefaults.standard.set(adBlockerOn, forKey: "AdBlockerOn")
        UserDefaults.standard.set(zoom, forKey: "Zoom")
        UserDefaults.standard.set(screenPersistenceOn, forKey: "ScreenPersistenceOn")
        UserDefaults.standard.set(lockScreenDimmingOn, forKey: "LockScreenDimmingOn")
        exitGracefully()
    }
    
    var body: some View {
        Form {
            List {
                Section(footer: Text("The app will quit.")) {
                    Button("Save Settings") {
                        saveSettings()
                    }
                }
                Section(footer: Text("Set the zoom level for the YouTube UI.")) {
                    Incrementer(value: $zoom)
                }
                Section(footer: Text("Block ads in videos. If you experience issues with playback, try disabling this option.")) {
                    Toggle(isOn: $adBlockerOn) {
                        Text("Block Ads (Beta)")
                    }
                }
                Section(footer: Text("Block sponsored segments in videos.")) {
                    Toggle(isOn: $sponsorBlockOn) {
                        Text("SponsorBlock")
                    }
                }
                Section(footer: Text("Bypass age restriction in videos.")) {
                    Toggle(isOn: $ageRestrictBypassOn) {
                        Text("Age Restriction Bypass")
                    }
                }
                Section(footer: Text("RECOMMENDED.\nCarTube requires the phone screen to be on at all times.\nThe Screen Persistence Helper will keep the phone screen on, even on the Lock Screen.")) {
                    Toggle(isOn: $screenPersistenceOn) {
                        Text("Screen Persistence Helper")
                    }
                }
                Section(footer: Text("RECOMMENDED.\nDim the Lock Screen while the app is running.")) {
                    Toggle(isOn: $lockScreenDimmingOn) {
                        Text("Lock Screen Dimming")
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
