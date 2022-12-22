//
//  ContentView.swift
//  CarTube
//
//  Created by Rory Madden on 22/12/22.
//

import SwiftUI

struct ContentView: View {
    private let defaults = UserDefaults.standard
    
    @Environment(\.openURL) var openURL
    
    @State private var urlString: String = ""
    @State private var sponsorBlockOn = UserDefaults.standard.bool(forKey: "SponsorBlockOn")
    @State private var adBlockerOn = UserDefaults.standard.bool(forKey: "AdBlockerOn")
    
    func extractVideoID(from link: String) -> String? {
        let regex = try! NSRegularExpression(pattern: "^(?:https?://)?(?:www\\.)?(?:m\\.|www\\.|)(?:youtu\\.be/|youtube\\.com/(?:embed/|v/|watch\\?v=|watch\\?.+&v=))((\\w|-){11})(?:\\S+)?$")
        guard let match = regex.firstMatch(in: link, range: NSRange(link.startIndex..., in: link)) else { return nil }
        guard let range = Range(match.range(at: 1), in: link) else { return nil }
        return String(link[range])
    }
    
    func playVideo() {
        if !CarPlaySingleton.shared.isCarPlayConnected() {
            UIApplication.shared.alert(body: "Phone is not connected to CarPlay.")
            return
        }
        
        if let urlID = self.extractVideoID(from: urlString) {
            let youtube = "https://www.youtube.com/embed/" + urlID + "?controls=0"
            CarPlaySingleton.shared.loadUrlString(urlString: youtube)
        } else {
            UIApplication.shared.alert(body: "Invalid YouTube link.")
        }
    }
    
    func saveSettings() {
        defaults.set(sponsorBlockOn, forKey: "SponsorBlockOn")
        defaults.set(adBlockerOn, forKey: "AdBlockerOn")
        exit(0)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField("YouTube URL", text: $urlString)
                    Button("Play on CarPlay") {
                        playVideo()
                    }
                }
                Section(header: Text("Settings")) {
                    Toggle(isOn: $sponsorBlockOn) {
                        Text("SponsorBlock")
                    }
                    Toggle(isOn: $adBlockerOn) {
                        Text("Ad Blocker")
                    }
                    Button("Save") {
                        saveSettings()
                    }
                }
            }.navigationTitle("CarTube")
            .toolbar {
                // Credit to SourceLocation
                // https://github.com/sourcelocation/AirTroller/blob/main/AirTroller/ContentView.swift
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        openURL(URL(string: "https://github.com/Avangelista/CarTube")!)
                    }) {
                        Image("github")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                    }
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        openURL(URL(string: "https://ko-fi.com/avangelista")!)
                    }) {
                        Image(systemName: "heart.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
