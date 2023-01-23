//
//  ContentView.swift
//  CarTube
//
//  Created by Rory Madden on 22/12/22.
//

import SwiftUI
import WebKit

// hacky, but mark any SwiftUI controller for easier identification later
protocol SwiftUIController: AnyObject {}
extension UIHostingController: SwiftUIController {}

struct ContentView: View {
    
    @Environment(\.openURL) var openURL
    @Environment(\.scenePhase) var scenePhase
    
    @State private var urlString: String = ""
    
    func playVideo() {
        if let urlID = extractYouTubeVideoID(urlString) {
            CarPlaySingleton.shared.dontAskAboutLastPlaying()
            let youtube = YT_EMBED + urlID
            CarPlaySingleton.shared.loadUrl(youtube)
        } else {
            UIApplication.shared.alert(body: "Invalid YouTube link.", window: .main)
        }
    }

    var body: some View {
        NavigationView {
            List {
                VStack {
                    HStack {
                        Spacer()
                        Image("cartube")
                        Spacer()
                    }
                    Text("CarTube").fontWeight(.bold).font(.system(size: 20))
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")").fontWeight(.light).font(.system(size: 12))
                    Text("Avangelista").fontWeight(.light).font(.system(size: 12))

                }.listRowBackground(Color.clear)
                Section {
                    TextField("YouTube URL", text: $urlString, onCommit: { playVideo() })
                    Button("Play on CarPlay") {
                        hideKeyboard()
                        playVideo()
                    }
                }
                Section {
                    NavigationLink(destination: HowTo(), label: { Text("How to Use") })
                    NavigationLink(destination: Settings(), label: { Text("Settings") })
                    NavigationLink(destination: Debug(), label: { Text("Debug") })
                }
            }
            .toolbar {
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
            }.navigationBarTitle("", displayMode: .inline)
        }.onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                let clipboard = UIPasteboard.general
                if clipboard.hasURLs {
                    if let clipboardUrl = clipboard.url?.absoluteString {
                        if isYouTubeURL(clipboardUrl) {
                            urlString = clipboardUrl
                        }
                    }
                }
            }
        }
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
