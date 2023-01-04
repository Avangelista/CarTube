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

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        window.frame = window.safeAreaLayoutGuide.layoutFrame
        let viewController = CarPlayViewController()
        window.rootViewController = viewController
        window.makeKeyAndVisible()
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        checkIfYouTubePlaying()
        CarPlaySingleton.shared.checkIfScreenOff()
    }
    
    func checkIfYouTubePlaying() {
        // Check if a video was playing on YouTube
        let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))

        // Get a Swift function for MRMediaRemoteGetNowPlayingInfo
        guard let MRMediaRemoteGetNowPlayingInfoPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString) else { return }
        typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
        let MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(MRMediaRemoteGetNowPlayingInfoPointer, to: MRMediaRemoteGetNowPlayingInfoFunction.self)

        // Get song info
        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main, { (information) in
            let bundleInfo = Dynamic._MRNowPlayingClientProtobuf.initWithData(information["kMRMediaRemoteNowPlayingInfoClientPropertiesData"])
            if bundleInfo.bundleIdentifier.asString == "com.google.ios.youtube" {
                guard let channelName = information["kMRMediaRemoteNowPlayingInfoArtist"] as? String else { return }
                guard let videoName = information["kMRMediaRemoteNowPlayingInfoTitle"] as? String else { return }
                UIApplication.shared.confirmAlert(title: "Video Detected", body: "Looks like you're watching a video on the YouTube app. Do you want to try to play it on CarPlay?", onOK: {
                    CarPlaySingleton.shared.searchVideo(search: "\(videoName) \(channelName)")
                }, noCancel: false)
            }
        })
    }
}

//class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    
    
//    var interfaceController: CPInterfaceController?
//    var carWindow: CPWindow?
//    func templateApplicationScene(
//        _ templateApplicationScene: CPTemplateApplicationScene,
//        didConnect interfaceController: CPInterfaceController, to window: CPWindow
//    ) {
//        print("triggered this")
////        print(templateApplicationScene._screen()?.currentMode)
//
//        self.interfaceController = interfaceController
////        self.interfaceController!.delegate = self
//        self.carWindow = window
//
////        window.sendEvent(UIEvent())
//
//        let viewController = CarPlayViewController()
//        window.rootViewController = viewController
//
//        let mapTemplate: CPMapTemplate = makeRootTemplate(vc: viewController)
//        // On real hardware, the root template appears to be set (interfaceController.rootTemplate has a value) but the template is not visible
////        self.interfaceController?.setRootTemplate(mapTemplate, animated: true, completion: nil)
//
//        let button = CPAlertAction.init(title: "Button", style: .default, handler: {_ in })
//        let alert = CPNavigationAlert.init(titleVariants: ["Worked"], subtitleVariants: nil, image: nil, primaryAction: button, secondaryAction: nil, duration: 30)
//        mapTemplate.present(navigationAlert: alert, animated: true)
//        CarPlaySingleton.shared.setWindow(window: window)
//    }
//
//    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController, from window: CPWindow) {
//        CarPlaySingleton.shared.removeCPVC()
//    }
//
//    func makeRootTemplate(vc: CarPlayViewController) -> CPMapTemplate {
//        let goBackTen = CPBarButton(image: UIImage(systemName: "gobackward.10")!, handler: {_ in vc.goBackTen() })
//        let playPauseButton = CPBarButton(image: UIImage(systemName: "playpause.fill")!, handler: {_ in vc.playPause() })
//        let goForwardTen = CPBarButton(image: UIImage(systemName: "goforward.10")!, handler: {_ in vc.goForwardTen() })
//        let mapTemplate = CPMapTemplate()
//        mapTemplate.leadingNavigationBarButtons = [playPauseButton]
//        mapTemplate.trailingNavigationBarButtons = [goForwardTen, goBackTen]
//        return mapTemplate
//    }
//}
