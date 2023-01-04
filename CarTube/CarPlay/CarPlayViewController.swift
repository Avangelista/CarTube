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
import Dynamic
import SwiftUI
import notify

// This is the view controller shown on an in car's head unit display with CarPlay.
class CarPlayViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    
    private var webView: WKWebView = WKWebView()
    private let defaults = UserDefaults.standard
    private var keyboardView: UIView = UIView()
    private var noSleepView: WKWebView = WKWebView()
    private var screenOffLabel: UIView = UIView()
    
    private var deviceLocked: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register self as the CarPlay view controller
        CarPlaySingleton.shared.setCPVC(controller: self)
        
        // Set up the main webview
        
        // Add any enabled scripts
        let sponsorBlockOn = defaults.bool(forKey: "SponsorBlockOn")
        let webConfiguration = WKWebViewConfiguration()
        var enabledScripts: [String] = []
        if sponsorBlockOn {
            enabledScripts.append("SponsorBlock")
        }

        // Add our custom CSS and JS
        enabledScripts.append("CustomLayout")

        enabledScripts.forEach { item in
            guard let scriptPath = Bundle.main.path(forResource: item, ofType: "js"),
                  let scriptSource = try? String(contentsOfFile: scriptPath) else { return }
            let userScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            webConfiguration.userContentController.addUserScript(userScript)
        }

        // Apply custom zoom
        let zoomScript = "if (!location.href.toString().includes('youtube.com/embed') && location.href.toString().includes('youtube.com')) { document.body.style.zoom = '\(defaults.integer(forKey: "zoom"))%' }";
        let zoomUserScript = WKUserScript(source: zoomScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webConfiguration.userContentController.addUserScript(zoomUserScript)

        webConfiguration.userContentController.add(self, name: "keyboard") // allow JS to activate the keyboard
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.allowsPictureInPictureMediaPlayback = false
        webConfiguration.allowsAirPlayForMediaPlayback = false
        webView = WKWebView(frame: view.bounds, configuration: webConfiguration)
        webView.scrollView.isScrollEnabled = false
        Dynamic(webView)._setSuppressSoftwareKeyboard(true)
        webView.allowsLinkPreview = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        // Check if the user tried to play something before CarPlay was loaded, otherwise load homepage
        if let urlString = CarPlaySingleton.shared.getCachedVideo() {
            CarPlaySingleton.shared.clearCachedVideo()
            loadUrl(urlString: urlString)
        } else {
            loadUrl(urlString: "https://m.youtube.com/")
        }
        
        self.view.addSubview(webView)
        
        // Add a separate hidden webview to disable screen sleep
        let noSleepViewConfig = WKWebViewConfiguration()
        guard let scriptPath = Bundle.main.path(forResource: "NoSleepEnable", ofType: "js"),
              let scriptSource = try? String(contentsOfFile: scriptPath) else { return }
        let userScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        noSleepViewConfig.userContentController.addUserScript(userScript)
        noSleepViewConfig.allowsInlineMediaPlayback = true
        noSleepViewConfig.requiresUserActionForMediaPlayback = false
        noSleepView = WKWebView(frame: view.bounds, configuration: noSleepViewConfig)
        noSleepView.load(URLRequest(url: URL(string: "about:blank")!))
        view.addSubview(noSleepView)
        noSleepView.isHidden = true
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            guard let sleepDisabledNoSleepView = Dynamic(self.noSleepView)._hasSleepDisabler.asBool else { return }
            guard let sleepDisabledWebView = Dynamic(self.webView)._hasSleepDisabler.asBool else { return }
            if sleepDisabledWebView {
                self.noSleepView.evaluateJavaScript("noSleep.disable()")
            }
            if !sleepDisabledNoSleepView && !sleepDisabledWebView {
                self.noSleepView.evaluateJavaScript("noSleep.enable()")
            }
        }
        
        // Add a view for our keyboard
        let keyboardController = UIHostingController(rootView: KeyboardView())
        self.addChild(keyboardController)
        self.view.addSubview(keyboardController.view)
        keyboardController.view.frame = CGRect(x: Int(view.bounds.origin.x), y: Int(view.bounds.height * 2/5), width: Int(view.bounds.width), height: Int(view.bounds.height * 3/5))
        self.keyboardView = keyboardController.view
        self.keyboardView.isHidden = true
        
        // Create a label that displays when the user turns their screen off
        screenOffLabel = UIView(frame: view.bounds)
        screenOffLabel.backgroundColor = .white
        screenOffLabel.isUserInteractionEnabled = false
        screenOffLabel.alpha = 0
        self.view.addSubview(screenOffLabel)
        let label = UILabel(frame: screenOffLabel.bounds)
        label.text = "Please tap your phone screen once to wake it."
        label.textAlignment = .center
        label.textColor = .black
        screenOffLabel.addSubview(label)
        
        // Register for screen off notifications
        registerForNotifications()
    }
    
    // Every time the user locks their phone, show a warning
    // Caveat: also fires any time the notification centre is shown
    func registerForNotifications() {
        var notify_token: Int32 = 0
        notify_register_dispatch("com.apple.springboard.lockstate", &notify_token, DispatchQueue.main, { token in
            var state: Int64 = 0
            notify_get_state(token, &state)
            
            self.deviceLocked = state == 1
            
            if self.deviceLocked! {
                self.showWarningLabel()
            }
        })
    }
    
    // Check if the screen is off right now
    // Caveat: will return True any time notification centre is showing and brightness is 0%
    func checkIfScreenOff() {
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
        
        let s3 = dlsym(sbs, "BKSDisplayBrightnessGetCurrent")
        let BKSDisplayBrightnessGetCurrent = unsafeBitCast(s3, to: (@convention(c) () -> Float).self)
        let brightness = BKSDisplayBrightnessGetCurrent()
        
        if lockStatus.boolValue && brightness == 0 {
            showWarningLabel()
        }
    }
    
    // Warn the user to tap their screen
    func showWarningLabel() {
        self.screenOffLabel.alpha = 1
        let timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { timer in
            UIView.animate(withDuration: 1, delay: 0, options: .curveLinear, animations: {
                self.screenOffLabel.alpha = 0
            }, completion: nil)
        }
    }
    
    // Send keystrokes to the web view
    func sendInput(input: String) {
        Dynamic(self.webView)._simulateTextEntered(input)
    }
    
    // Send a backspace to the web view
    func backspaceInput() {
        self.webView.evaluateJavaScript("document.activeElement.value = document.activeElement.value.slice(0, -1);")
        Dynamic(self.webView)._simulateTextEntered("\0") // dumb but necessary for search results to update as we type
        self.webView.evaluateJavaScript("document.activeElement.value = document.activeElement.value.slice(0, -1);")
    }
    
    // Simulate pressing enter, doesn't work on some devices, not used
    func submitInput() {
        self.webView.evaluateJavaScript("document.activeElement.form.requestSubmit()")
    }
    
    // Load a string as a URL into the web view
    func loadUrl(urlString: String) {
        let url = URL(string: urlString)!
        webView.load(URLRequest(url: url))
    }
    
    // Show or hide the keyboard
    func toggleKeyboard() {
        keyboardView.isHidden = !keyboardView.isHidden
    }
    
    // Helper func for JS to show or hide the keyboard
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "keyboard" {
            if message.body as! String == "hide" {
                self.keyboardView.isHidden = true
            } else if message.body as! String == "show" {
                self.keyboardView.isHidden = false
            }
        }
    }
    
    // Perform any necessary tricks after a page finishes loading
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let url = webView.url else { self.loadUrl(urlString: "https://m.youtube.com/"); return }
        // Check we're on an embedded video
        if url.absoluteString.contains("youtube.com/embed") {
            // Check for errors playing video (e.g. if the uploader has disabled embedding)
            self.webView.evaluateJavaScript("document.getElementsByClassName('ytp-error').length") { (result, error) in
                if error == nil {
                    if let length = result as? Int, length != 0 {
                        self.loadUrl(urlString: "https://m.youtube.com/")
                    }
                } else {
                    self.loadUrl(urlString: "https://m.youtube.com/")
                }
            }
            // Press play
            self.webView.evaluateJavaScript("document.getElementsByClassName('ytp-large-play-button')[0].click()")
            // Create close button
            self.webView.evaluateJavaScript("const btn = document.createElement('button'); btn.setAttribute('style', 'margin-top: 10px; width: 48px; height: 48px; border-radius: 100px; background: white;'); btn.setAttribute('onclick', 'window.open(\"https://m.youtube.com/\")'); btn.innerHTML = '<svg width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"black\"><path d=\"M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z\"/><path d=\"M0 0h24v24H0z\" fill=\"none\"/></svg>'; const topBtns = document.getElementsByClassName('ytp-chrome-top-buttons')[0]; topBtns.innerHTML = ''; topBtns.appendChild(btn)")
//            self.webView.evaluateJavaScript("const btn = document.createElement('button'); btn.setAttribute('style', 'position: fixed; top: 25px; right: 10px; width: 50px; height: 50px; border-radius: 100px; background: white;'); btn.setAttribute('onclick', 'window.open(\"https://m.youtube.com/\")'); btn.innerHTML = '<svg width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"black\"><path d=\"M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z\"/><path d=\"M0 0h24v24H0z\" fill=\"none\"/></svg>'; document.getElementsByClassName('ytp-title-text')[0].appendChild(btn)")
        }
    }

    // Stop the web view from creating any new web views, handle them here
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            guard let urlString = navigationAction.request.url?.absoluteString else { return nil }
            if let urlID = CarPlaySingleton.extractVideoID(from: urlString) {
                let youtube = "https://www.youtube.com/embed/" + urlID
                loadUrl(urlString: youtube)
            } else {
                loadUrl(urlString: urlString)
            }
        }
        return nil
    }
}
