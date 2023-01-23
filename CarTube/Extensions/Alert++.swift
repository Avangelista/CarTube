//
//  Alert++.swift
//  Evyrest
//
//  Created by exerhythm on 14.12.2022.
//

import UIKit

var currentUIAlertController: UIAlertController?

enum WindowType {
    case main
    case carPlay
}

extension UIApplication {
    func dismissAlert(animated: Bool) {
        DispatchQueue.main.async {
            currentUIAlertController?.dismiss(animated: animated)
        }
    }
    func alert(title: String = "Error", body: String, animated: Bool = true, withButton: Bool = true, window: WindowType = .main) {
        DispatchQueue.main.async {
            currentUIAlertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
            if withButton { currentUIAlertController?.addAction(.init(title: "OK", style: .cancel)) }
            self.present(alert: currentUIAlertController!, window: window)
        }
    }
    func confirmAlert(title: String = "Error", body: String, onOK: @escaping () -> (), noCancel: Bool = false, window: WindowType = .main) {
        DispatchQueue.main.async {
            currentUIAlertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
            if !noCancel {
                currentUIAlertController?.addAction(.init(title: "No", style: .cancel))
            }
            currentUIAlertController?.addAction(.init(title: "Yes", style: noCancel ? .cancel : .default, handler: { _ in
                onOK()
            }))
            self.present(alert: currentUIAlertController!, window: window)
        }
    }
    func change(title: String = "Error", body: String) {
        DispatchQueue.main.async {
            currentUIAlertController?.title = title
            currentUIAlertController?.message = body
        }
    }
    
    func getPreferredController(window: WindowType) -> UIViewController? {
        for w in self.windows {
            if w.rootViewController is SwiftUIController && window == .main {
                return w.rootViewController
            } else if w.rootViewController is CarPlayViewController && window == .carPlay {
                return w.rootViewController
            }
        }
        return nil
    }
    
    func present(alert: UIAlertController, window: WindowType) {
        alert.view.tintColor = .label
        if var topController = getPreferredController(window: window) {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            topController.present(alert, animated: true)
            // topController should now be your topmost view controller
        }
    }
}
