//
//  CarPlaySceneDelegate.swift
//  TrollTubeTest
//
//  Created by Rory Madden on 20/12/22.
//

import Foundation
import CarPlay

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    var interfaceController: CPInterfaceController?
    var carWindow: CPWindow?

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController, to window: CPWindow
    ) {
        self.interfaceController = interfaceController
//        self.interfaceController!.delegate = self
        self.carWindow = window

        let viewController = CarPlayViewController()
        window.rootViewController = viewController

        let mapTemplate: CPMapTemplate = makeRootTemplate(vc: viewController)
        // On real hardware, the root template appears to be set (interfaceController.rootTemplate has a value) but the template is not visible
        self.interfaceController?.setRootTemplate(mapTemplate, animated: true, completion: nil)

        let button = CPAlertAction.init(title: "Button", style: .default, handler: {_ in })
        let alert = CPNavigationAlert.init(titleVariants: ["Worked"], subtitleVariants: nil, image: nil, primaryAction: button, secondaryAction: nil, duration: 30)
        mapTemplate.present(navigationAlert: alert, animated: true)
        CarPlaySingleton.shared.setWindow(window: window)
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController, from window: CPWindow) {
        CarPlaySingleton.shared.removeCPVC()
    }
    
    func makeRootTemplate(vc: CarPlayViewController) -> CPMapTemplate {
        let goBackTen = CPBarButton(image: UIImage(systemName: "gobackward.10")!, handler: {_ in vc.goBackTen() })
        let playPauseButton = CPBarButton(image: UIImage(systemName: "playpause.fill")!, handler: {_ in vc.playPause() })
        let goForwardTen = CPBarButton(image: UIImage(systemName: "goforward.10")!, handler: {_ in vc.goForwardTen() })
        let mapTemplate = CPMapTemplate()
        mapTemplate.leadingNavigationBarButtons = [playPauseButton]
        mapTemplate.trailingNavigationBarButtons = [goForwardTen, goBackTen]
        return mapTemplate
    }
}
