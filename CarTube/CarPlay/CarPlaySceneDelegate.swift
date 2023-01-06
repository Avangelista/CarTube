//
//  CarPlaySceneDelegate.swift
//  TrollTubeTest
//
//  Created by Rory Madden on 20/12/22.
//

import Foundation
import CarPlay
import Dynamic
import AVFAudio

class CarPlaySceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var viewController: UIViewController?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        window.frame = window.safeAreaLayoutGuide.layoutFrame
        viewController = CarPlayViewController()
        window.rootViewController = viewController
        window.makeKeyAndVisible()
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        CarPlaySingleton.shared.setCPWindowActive(true)
        checkIfYouTubePlaying()
        CarPlaySingleton.shared.enablePersistence()
        // if the screen is off or locked we should dim it in preparation
        if isScreenLocked() {
            if getScreenBrightness() == 0 {
                CarPlaySingleton.shared.showScreenOffWarning()
            }
            CarPlaySingleton.shared.setLowBrightness()
        }
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // if the screen is locked we should undim it
        if isScreenLocked() {
            CarPlaySingleton.shared.restoreBrightness()
        }
        CarPlaySingleton.shared.setCPWindowActive(false)
        CarPlaySingleton.shared.disablePersistence()
    }
    
    func checkIfYouTubePlaying() {
        getNowPlaying { result in
            switch result {
            case .success(let nowPlaying):
                if nowPlaying.bundleID == "com.google.ios.youtube" {
                    UIApplication.shared.confirmAlert(title: "Video Detected", body: "Looks like you're watching a video on the YouTube app. Do you want to try to play it on CarPlay?", onOK: {
                        CarPlaySingleton.shared.searchVideo("\(nowPlaying.title) \(nowPlaying.artist)")
                    }, noCancel: false, window: .carPlay)
                }
            case .failure(let error):
                print(error)
            }
        }
    }
}
