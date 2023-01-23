//
//  CarPlayViewController.swift
//  TrollTubeTest
//
//  Created by Rory Madden on 20/12/22.
//

import WebKit
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
        let ageRestrictBypassOn = UserDefaults.standard.bool(forKey: "AgeRestrictBypassOn")
        let adBlockerOn = UserDefaults.standard.bool(forKey: "AdBlockerOn")
        let webConfiguration = WKWebViewConfiguration()
        var enabledScripts: [String] = []
        if sponsorBlockOn {
            enabledScripts.append("SponsorBlock")
        }
        if ageRestrictBypassOn {
            enabledScripts.append("AgeRestrictBypass")
        }
        if adBlockerOn {
            enabledScripts.append("AdBlocker")
        }

        // Add our custom CSS and JS
        enabledScripts.append("CustomLayout")
        
        enabledScripts.forEach { item in
            guard let scriptPath = Bundle.main.path(forResource: item, ofType: "js"),
                  let scriptSource = try? String(contentsOfFile: scriptPath) else { return }
            let userScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            webConfiguration.userContentController.addUserScript(userScript)
        }

        // Apply custom zoom & hide the open app button
        let zoomScript = "let meta = document.createElement('meta'); meta.name = 'viewport'; meta.content = 'initial-scale=\(Double(UserDefaults.standard.integer(forKey: "Zoom")) / 100.0), maximum-scale=\(Double(UserDefaults.standard.integer(forKey: "Zoom")) / 100.0), user-scalable=no'; const head = document.head; head.appendChild(meta); let css = document.createElement('style'); css.type = 'text/css'; css.innerHTML = '.open-app-button { display: none; }'; head.appendChild(css);"
        let zoomUserScript = WKUserScript(source: zoomScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webConfiguration.userContentController.addUserScript(zoomUserScript)

        webConfiguration.userContentController.add(self, name: "keyboard") // allow JS to activate the keyboard
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.allowsPictureInPictureMediaPlayback = false
        webConfiguration.allowsAirPlayForMediaPlayback = false
        webConfiguration.requiresUserActionForMediaPlayback = false
        webView = WKWebView(frame: view.frame, configuration: webConfiguration)
        webView.allowsLinkPreview = false
        webView.allowsBackForwardNavigationGestures = false
        webView.scrollView.minimumZoomScale = 1
        webView.scrollView.maximumZoomScale = 1
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        // Add recogniser for refreshing
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reloadWebView(_:)), for: .valueChanged)
        webView.scrollView.addSubview(refreshControl)
        
        // Add recognisers for back and forward
        let swipeLeftRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(recognizer:)))
        let swipeRightRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(recognizer:)))
        swipeLeftRecognizer.direction = .left
        swipeRightRecognizer.direction = .right
        webView.addGestureRecognizer(swipeLeftRecognizer)
        webView.addGestureRecognizer(swipeRightRecognizer)
        
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
        
        let splashController = UIHostingController(rootView: SplashScreen())
        self.addChild(splashController)
        splashController.view.frame = view.bounds
        splashController.view.isUserInteractionEnabled = false
        self.view.addSubview(splashController.view)
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            UIView.animate(withDuration: 1, delay: 0, options: .curveEaseInOut, animations: {
                splashController.view.alpha = 0
            }, completion: {_ in
                splashController.removeFromParent()
            })
        }
    }
    
    // Refresh webpage
    @objc func reloadWebView(_ sender: UIRefreshControl) {
        webView.reload()
        sender.endRefreshing()
    }
    
    // Back and forward navigation
    @objc private func handleSwipe(recognizer: UISwipeGestureRecognizer) {
        if (recognizer.direction == .left) {
            if webView.canGoForward {
                webView.goForward()
                
                let arrowImageView = UIImageView(image: UIImage(systemName: "arrow.right"))
                arrowImageView.isUserInteractionEnabled = false
                arrowImageView.tintColor = .white
                arrowImageView.frame.size.width = arrowImageView.frame.size.width * 2
                arrowImageView.frame.size.height = arrowImageView.frame.size.height * 2
                arrowImageView.frame.origin.x = view.frame.width
                arrowImageView.frame.origin.y = (view.frame.height / 2) - (arrowImageView.frame.size.height / 2)
                arrowImageView.layer.shadowColor = UIColor.black.cgColor
                arrowImageView.layer.shadowOpacity = 0.5
                arrowImageView.layer.shadowOffset = CGSize(width: 2, height: 2)
                arrowImageView.layer.shadowRadius = 5
                view.addSubview(arrowImageView)

                UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [], animations: {
                    arrowImageView.frame.origin.x -= arrowImageView.frame.width * 1.4
                }, completion: {_ in
                    UIView.animate(withDuration: 0.1, animations: {
                        arrowImageView.alpha = 0
                    }, completion: {_ in
                        arrowImageView.removeFromSuperview()
                    })
                })
            }
        }

        if (recognizer.direction == .right) {
            if webView.canGoBack {
                webView.goBack()
                
                let arrowImageView = UIImageView(image: UIImage(systemName: "arrow.left"))
                arrowImageView.isUserInteractionEnabled = false
                arrowImageView.tintColor = .white
                arrowImageView.frame.size.width = arrowImageView.frame.size.width * 2
                arrowImageView.frame.size.height = arrowImageView.frame.size.height * 2
                arrowImageView.frame.origin.x = -arrowImageView.frame.width
                arrowImageView.frame.origin.y = (view.frame.height / 2) - (arrowImageView.frame.size.height / 2)
                arrowImageView.layer.shadowColor = UIColor.black.cgColor
                arrowImageView.layer.shadowOpacity = 0.5
                arrowImageView.layer.shadowOffset = CGSize(width: 2, height: 2)
                arrowImageView.layer.shadowRadius = 5
                view.addSubview(arrowImageView)

                UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [], animations: {
                    arrowImageView.frame.origin.x += arrowImageView.frame.width * 1.4
                }, completion: {_ in
                    UIView.animate(withDuration: 0.1, animations: {
                        arrowImageView.alpha = 0
                    }, completion: {_ in
                        arrowImageView.removeFromSuperview()
                    })
                })
            }
        }
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
                let sleepDisabledNoSleepView = self.noSleepView._hasSleepDisabler()
                let sleepDisabledWebView = self.webView._hasSleepDisabler()
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
        webView._simulateTextEntered(input)
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
        let youtubeURL = URL(string: urlString)!
        let youtubeRequest = URLRequest(url: youtubeURL)
//        youtubeRequest.setValue(YT_HOME, forHTTPHeaderField: "Referer")
        webView.load(youtubeRequest)
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

    }

    // Stop the web view from creating any new web views, handle them here
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            guard let urlString = navigationAction.request.url?.absoluteString else { return nil }
            loadUrl(urlString)
        }
        return nil
    }
}
