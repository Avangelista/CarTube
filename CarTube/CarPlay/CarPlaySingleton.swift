//
//  CarPlaySingleton.swift
//  TrollTubeTest
//
//  Created by Rory Madden on 20/12/22.
//

import Foundation
import CarPlay
import Dynamic

class CarPlaySingleton {
    static let shared = CarPlaySingleton()
    private var window: UIWindow?
    private var controller: CarPlayViewController?
    private var cachedVideo: String?
    
    func loadVideo(urlString: String) {
        if (Dynamic.AVExternalDevice.currentCarPlayExternalDevice.asAnyObject == nil) {
            UIApplication.shared.alert(body: "CarPlay not connected.")
        } else if controller == nil {
            self.cachedVideo = urlString
        } else {
            controller?.loadUrl(urlString: urlString)
        }
    }
    
    func searchVideo(search: String) {
        let searchString = "https://m.youtube.com/results?search_query=\(search)"
        guard let safeSearch = searchString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        loadVideo(urlString: safeSearch)
    }
    
    func checkIfScreenOff() {
        controller?.checkIfScreenOff()
    }
    
    func sendInput(input: String) {
        controller?.sendInput(input: input)
    }
    
    func backspaceInput() {
        controller?.backspaceInput()
    }
    
    func submitInput() {
        controller?.submitInput()
    }
    
    func goHome() {
        controller?.loadUrl(urlString: "https://m.youtube.com/")
    }
    
    func toggleKeyboard() {
        controller?.toggleKeyboard()
    }
    
    func getCachedVideo() -> String? {
        return cachedVideo
    }
    
    func clearCachedVideo() {
        cachedVideo = nil
    }
    
    func isCarPlayConnected() -> Bool {
        return controller != nil
    }
    
    func setCPVC(controller: CarPlayViewController) {
        self.controller = controller
    }
    
    func getCPVC() -> CarPlayViewController? {
        return self.controller
    }
    
    func removeCPVC() {
        self.controller = nil
    }

    func setWindow(window: UIWindow) {
        self.window = window
    }
    
    func getWindow() -> UIWindow? {
        return self.window
    }
    
    static func extractVideoID(from link: String) -> String? {
        let regex = try! NSRegularExpression(pattern: "^(?:https?://)?(?:www\\.)?(?:m\\.|www\\.|)(?:youtu\\.be/|youtube\\.com/(?:embed/|v/|watch\\?v=|watch\\?.+&v=))((\\w|-){11})(?:\\S+)?$")
        guard let match = regex.firstMatch(in: link, range: NSRange(link.startIndex..., in: link)) else { return nil }
        guard let range = Range(match.range(at: 1), in: link) else { return nil }
        return String(link[range])
    }
}
