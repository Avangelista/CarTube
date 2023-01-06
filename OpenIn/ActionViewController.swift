//
//  ActionViewController.swift
//  OpenLink
//
//  Created by Rory Madden on 21/12/22.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class ActionViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
            
        for item in self.extensionContext!.inputItems as! [NSExtensionItem] {
            for provider in item.attachments! {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { url, error in
                        if let error = error {
                            print("Error retrieving URL: \(error)")
                        } else if let url = url as? URL {
                            print("Shared URL: \(url)")
                            // You can now use the `url` variable to access the shared URL
                            if let urlID = self.extractVideoID(from: url.absoluteString) {
                                let scheme = "cartube://" + urlID
                                let newUrl: URL = URL(string: scheme)!
                                self.openApp(url: newUrl)
                            } else {
                                let scheme = "cartube://"
                                let newUrl: URL = URL(string: scheme)!
                                self.openApp(url: newUrl)
                                
                            }
                        }
                    }
                }
            }
        }
            
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        for item in self.extensionContext!.inputItems as! [NSExtensionItem] {
//            for provider in item.attachments! {
//                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
//                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { url, error in
//                        if let error = error {
//                            print("Error retrieving URL: \(error)")
//                        } else if let url = url as? URL {
//                            print("Shared URL: \(url)")
//                            // You can now use the `url` variable to access the shared URL
//                            if let urlID = self.extractVideoID(from: url.absoluteString) {
//                                let scheme = "cartube://" + urlID
//                                let newUrl: URL = URL(string: scheme)!
//                                self.openApp(url: newUrl)
//                            } else {
//                                let scheme = "cartube://"
//                                let newUrl: URL = URL(string: scheme)!
//                                self.openApp(url: newUrl)
//                            }
//                        }
//                    }
//                }
//            }
//        }
//
//        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
//    }
    
    func extractVideoID(from link: String) -> String? {
        let regex = try! NSRegularExpression(pattern: "^(?:https?://)?(?:www\\.)?(?:m\\.|www\\.|)(?:youtu\\.be/|youtube\\.com/(?:embed/|v/|watch\\?v=|watch\\?.+&v=))((\\w|-){11})(?:\\S+)?$")
        guard let match = regex.firstMatch(in: link, range: NSRange(link.startIndex..., in: link)) else { return nil }
        guard let range = Range(match.range(at: 1), in: link) else { return nil }
        return String(link[range])
    }
    
    func openApp(url: URL) {
          var responder = self as UIResponder?
          responder = (responder as? UIViewController)?.parent
          while (responder != nil && !(responder is UIApplication)) {
             responder = responder?.next
          }
          if responder != nil{
             let selectorOpenURL = sel_registerName("openURL:")
             if responder!.responds(to: selectorOpenURL) {
                responder!.perform(selectorOpenURL, with: url)
             }
         }
     }
}
