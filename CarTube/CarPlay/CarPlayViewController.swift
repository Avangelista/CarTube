//
//  CarPlayViewController.swift
//  TrollTubeTest
//
//  Created by Rory Madden on 20/12/22.
//

import Foundation
import UIKit
import AVFoundation
import WebKit
import MapKit
import CarPlay
import JavaScriptCore

enum VideoState {
    case unloaded
    case loaded
    case play
    case pause
}

// This is the view controller shown on an in car's head unit display with CarPlay.
class CarPlayViewController: UIViewController, WKNavigationDelegate {
    private var webView: WKWebView = WKWebView()
    private var videoState = VideoState.unloaded
    private let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        CarPlaySingleton.shared.setCPVC(controller: self)

//        let window = CarPlaySingleton.shared.getWindow()!
        
        let sponsorBlockOn = defaults.bool(forKey: "SponsorBlockOn")
        let adBlockerOn = defaults.bool(forKey: "AdBlockerOn")
        let contentController = WKUserContentController()
        var enabledScripts: [String] = []
        if sponsorBlockOn {
            enabledScripts.append("SponsorBlock")
        }
        if adBlockerOn {
            enabledScripts.append("AdBlocker")
        }

        enabledScripts.forEach { item in
            guard let scriptPath = Bundle.main.path(forResource: item, ofType: "js"),
                  let scriptSource = try? String(contentsOfFile: scriptPath) else { print("failed"); return }
            let userScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            contentController.addUserScript(userScript)
        }
        
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController = contentController
        webConfiguration.allowsInlineMediaPlayback = true
        webView = WKWebView(frame: view.frame, configuration: webConfiguration)
        webView.navigationDelegate = self
        
        if let urlString = CarPlaySingleton.shared.storedUrl() {
            print("Url found")
            loadUrl(urlString: urlString)
        } else {
            print("No cached url")
        }

        self.view = webView
    }
    
    func loadUrl(urlString: String) {
        let url = URL(string: urlString)!
        webView.load(URLRequest(url: url))
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.webView.evaluateJavaScript("document.getElementsByClassName('ytp-large-play-button')[0].click()") { (result, error) in
            if error == nil {
                self.videoState = .play
            } else {
                self.videoState = .loaded
            }
        }
    }
    
    func goBackTen() {
        webView.evaluateJavaScript("document.getElementsByTagName('video')[0].currentTime -= 10")
    }
    
    func goForwardTen() {
        webView.evaluateJavaScript("document.getElementsByTagName('video')[0].currentTime += 10")
    }
    
    func playPause() {
        if self.videoState == .play {
            webView.evaluateJavaScript("document.getElementsByTagName('video')[0].pause()")
            self.videoState = .pause
        } else if self.videoState == .pause {
            webView.evaluateJavaScript("document.getElementsByTagName('video')[0].play()")
            self.videoState = .play
        } else if self.videoState == .loaded {
            self.webView.evaluateJavaScript("document.getElementsByClassName('ytp-large-play-button')[0].click()")
            self.videoState = .play
        }
        
    }
}
