//
//  CarPlaySceneDelegate.swift
//  TrollTubeTest
//
//  Created by Rory Madden on 20/12/22.
//

import Foundation
import UIKit

class CarPlaySceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var viewController: UIViewController?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        viewController = CarPlayViewController()
        window.rootViewController = viewController
        window.makeKeyAndVisible()
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        CarPlaySingleton.shared.setCPWindowActive(true)
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
        CarPlaySingleton.shared.disablePersistence()
        CarPlaySingleton.shared.setCPWindowActive(false)
    }
}
