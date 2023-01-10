//
//  CarPlayViewController.swift
//  TrollTubeTest
//
//  Created by Rory Madden on 20/12/22.
//

import WebKit
import Dynamic
import SwiftUI

// This is the view controller shown on an in car's head unit display with CarPlay.
class CarPlayViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    
    private var webView: WKWebView = WKWebView()
    private var keyboardView: UIView = UIView()
    private var noSleepView: WKWebView = WKWebView()
    private var screenOffLabel: UIView = UIView()
    private var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register self as the CarPlay view controller
        CarPlaySingleton.shared.setCPVC(controller: self)
        
        // Check if the user was watching YouTube before they got in the car
        CarPlaySingleton.shared.checkIfYouTubePlaying()
        
        // Set up the main webview
        
        // Add any enabled scripts
        let sponsorBlockOn = UserDefaults.standard.bool(forKey: "SponsorBlockOn")
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
        let zoomScript = "if (!location.href.toString().includes('youtube.com/embed') && location.href.toString().includes('youtube.com')) { document.body.style.zoom = '\(UserDefaults.standard.integer(forKey: "Zoom"))%' }";
        let zoomUserScript = WKUserScript(source: zoomScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webConfiguration.userContentController.addUserScript(zoomUserScript)

        webConfiguration.userContentController.add(self, name: "keyboard") // allow JS to activate the keyboard
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.allowsPictureInPictureMediaPlayback = false
        webConfiguration.allowsAirPlayForMediaPlayback = false
        webView = WKWebView(frame: view.bounds, configuration: webConfiguration)
        webView.scrollView.isScrollEnabled = false
        webView.allowsLinkPreview = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        // Check if the user tried to play something before CarPlay was loaded, otherwise load homepage
        if let urlString = CarPlaySingleton.shared.getCachedVideo() {
            CarPlaySingleton.shared.clearCachedVideo()
            loadUrl(urlString)
        } else {
            goHome()
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
        
        // Add a view for our keyboard
        let keyboardController = UIHostingController(rootView: KeyboardView(width: view.bounds.width))
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
        label.text = "Tap your phone screen once to resume CarTube."
        label.textAlignment = .center
        label.textColor = .black
        screenOffLabel.addSubview(label)
    }
    
    func disablePersistence() {
        timer?.invalidate()
        timer = nil
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            self.noSleepView.evaluateJavaScript("noSleep.disable()")
        }
    }
    
    func enablePersistence() {
        // I don't love using timers, I'll fix this up later with play/pause event listeners
        if timer == nil {
            self.noSleepView.evaluateJavaScript("noSleep.enable()")
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                guard let sleepDisabledNoSleepView = Dynamic(self.noSleepView)._hasSleepDisabler.asBool else { return }
                guard let sleepDisabledWebView = Dynamic(self.webView)._hasSleepDisabler.asBool else { return }
                if sleepDisabledWebView {
                    self.noSleepView.evaluateJavaScript("noSleep.disable()")
                }
                if !sleepDisabledNoSleepView && !sleepDisabledWebView {
                    self.noSleepView.evaluateJavaScript("noSleep.enable()")
                }
            }
        }
    }
    
    // Warn the user to tap their screen
    func showWarningLabel() {
        self.screenOffLabel.alpha = 1
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            UIView.animate(withDuration: 1, delay: 0, options: .curveEaseInOut, animations: {
                self.screenOffLabel.alpha = 0
            }, completion: nil)
        }
    }
    
    // Send keystrokes to the web view
    func sendInput(_ input: String) {
        Dynamic(self.webView)._simulateTextEntered(input)
    }
    
    // Send a backspace to the web view
    func backspaceInput() {
        // not recommended, but works
        self.webView.evaluateJavaScript("document.execCommand('delete')")
    }
    
    // Go to YouTube homepage
    func goHome() {
        loadUrl(YT_HOME)
    }
    
    // Go back
    func goBack() {
        webView.goBack()
    }
    
    // Load a string as a URL into the web view
    func loadUrl(_ urlString: String) {
        let url = URL(string: urlString)!
        webView.load(URLRequest(url: url))
    }
    
    // Show or hide the keyboard
    func toggleKeyboard() {
        if keyboardView.isHidden {
            self.keyboardView.isHidden = false
            self.webView.frame.size.height = view.bounds.size.height - self.keyboardView.frame.size.height
        } else {
            self.keyboardView.isHidden = true
            self.webView.frame.size.height = view.bounds.size.height
        }
    }
    
    // Helper func for JS to show or hide the keyboard
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "keyboard" {
            if message.body as? String == "hide" {
                self.keyboardView.isHidden = true
                self.webView.frame.size.height = view.bounds.size.height
            } else if message.body as? String == "show" {
                self.keyboardView.isHidden = false
                self.webView.frame.size.height = view.bounds.size.height - self.keyboardView.frame.size.height
            }
        }
    }
    
    // Perform any necessary tricks after a page finishes loading
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let url = webView.url else { goHome(); return }
        
        // Check we're on an embedded video
        if url.absoluteString.contains(YT_EMBED) {
            // Check for errors playing video (e.g. if the uploader has disabled embedding)
            self.webView.evaluateJavaScript("document.getElementsByClassName('ytp-error').length") { (result, error) in
                if error == nil {
                    if let length = result as? Int, length != 0 {
                        UIApplication.shared.alert(body: "This video can't be played. It's likely the uploader disabled embedding.", window: .carPlay)
                        self.goHome()
                        return
                    }
                } else {
                    self.goHome()
                    return
                }
            }
            // Dumb fix but sometimes the persistence helper steals the focus from the video, so force it to play
            self.webView.evaluateJavaScript("document.getElementsByTagName('video')[0].addEventListener('loadeddata', (e) => { for (let i = 0; i < 10; i++) { setTimeout(function() { e.target.play() }, 200 * i) } })")
            // Press play
            self.webView.evaluateJavaScript("document.getElementsByClassName('ytp-large-play-button')[0].click()")
            // Create close button
            self.webView.evaluateJavaScript("const btn = document.createElement('button'); btn.textContent = 'Close'; btn.setAttribute('style', 'font-size: 18px; position: fixed; top: 12px; right: 10px;'); btn.setAttribute('onclick', 'window.open(\"https://m.youtube.com/\")');  document.getElementsByClassName('ytp-title-text')[0].appendChild(btn); const topBar = document.getElementsByClassName('ytp-chrome-top')[0]; topBar.style.width = (window.outerWidth - 120) + 'px';")
        }
    }

    // Stop the web view from creating any new web views, handle them here
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            guard let urlString = navigationAction.request.url?.absoluteString else { return nil }
            if let urlID = extractYouTubeVideoID(urlString) {
                let youtube = YT_EMBED + urlID
                loadUrl(youtube)
            } else {
                loadUrl(urlString)
            }
        }
        return nil
    }
}
