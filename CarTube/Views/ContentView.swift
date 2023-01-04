//
//  ContentView.swift
//  CarTube
//
//  Created by Rory Madden on 22/12/22.
//

import SwiftUI
import Dynamic
import MediaPlayer
import CoreFoundation

struct ContentView: View {
    private let defaults = UserDefaults.standard
    
    @Environment(\.openURL) var openURL
    @Environment(\.scenePhase) var scenePhase
    
    @State private var urlString: String = ""
    @State private var zoom = UserDefaults.standard.integer(forKey: "zoom")
    @State private var sponsorBlockOn = UserDefaults.standard.bool(forKey: "SponsorBlockOn")
    
    func playVideo() {
        if let urlID = CarPlaySingleton.extractVideoID(from: urlString) {
            let youtube = "https://www.youtube.com/embed/" + urlID
            CarPlaySingleton.shared.loadVideo(urlString: youtube)
        } else {
            UIApplication.shared.alert(body: "Invalid YouTube link.")
        }
    }
    
    func saveSettings() {
        defaults.set(sponsorBlockOn, forKey: "SponsorBlockOn")
        defaults.set(zoom, forKey: "zoom")
        // Exit gracefully
        UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            exit(0)
        }
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
                    Incrementer(value: $zoom)
                    Toggle(isOn: $sponsorBlockOn) {
                        Text("SponsorBlock")
                    }
                    Button("Save") {
                        isAutoBrightnessEnabled()
//                        saveSettings()
                    }
                }
                Section(header: Text("Debug")) {
                    Button("Toggle Keyboard") {
                        CarPlaySingleton.shared.toggleKeyboard()
                    }
                    Button("YouTube Homepage") {
                        CarPlaySingleton.shared.goHome()
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
        }.onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                let clipboard = UIPasteboard.general
                if clipboard.hasURLs {
                    if let clipboardUrl = clipboard.url {
                        if CarPlaySingleton.extractVideoID(from: clipboardUrl.absoluteString) != nil {
                            urlString = clipboardUrl.absoluteString
                        }
                    }
                }
            } else if newPhase == .inactive {
                print("Inactive")
            } else if newPhase == .background {
                print("Background")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
