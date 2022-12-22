//
//  CarPlaySingleton.swift
//  TrollTubeTest
//
//  Created by Rory Madden on 20/12/22.
//

import Foundation
import CarPlay

class CarPlaySingleton {
    static let shared = CarPlaySingleton()
    private var window: CPWindow?
    private var controller: CarPlayViewController?
    private var urlString: String?
    
    func loadUrlString(urlString: String) {
        if controller != nil {
            controller?.loadUrl(urlString: urlString)
        } else {
            self.urlString = urlString
        }
    }
    
    func isCarPlayConnected() -> Bool {
        return controller != nil
    }
    
    func storedUrl() -> String? {
        return urlString
    }
    
    func setCPVC(controller: CarPlayViewController) {
        self.controller = controller
    }
    
    func removeCPVC() {
        self.controller = nil
    }

    func setWindow(window: CPWindow) {
        self.window = window
    }
    
    func getWindow() -> CPWindow? {
        return self.window
    }
}
