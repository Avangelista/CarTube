// Open in Yatee
// https://github.com/yattee/yattee/tree/main/Open%20in%20Yattee
// GNU AGPLv3
// Modified

import Social
import UIKit
import UniformTypeIdentifiers

final class ShareViewController: SLComposeServiceViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        openExtensionContextURLs()
    }

    private func openExtensionContextURLs() {
        for item in extensionContext?.inputItems as! [NSExtensionItem] {
            if let attachments = item.attachments {
                tryToOpenItemForUrlTypeIdentifier(attachments)
                tryToOpenItemForPlainTextTypeIdentifier(attachments)
            }
        }
    }

    private func tryToOpenItemForPlainTextTypeIdentifier(_ attachments: [NSItemProvider]) {
        for itemProvider in attachments {
            itemProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                if let url = (item as? String),
                   let absoluteURL = URL(string: url)?.absoluteURL
                {
                    if let urlID = self.extractVideoID(from: absoluteURL.absoluteString) {
                        if let url = URL(string: "cartube://\(urlID)") {
                            self.open(url: url)
                        }
                    } else {
                        if let url = URL(string: "cartube://") {
                            self.open(url: url)
                        }
                    }
                    self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                }
            }
        }
    }

    private func tryToOpenItemForUrlTypeIdentifier(_ attachments: [NSItemProvider]) {
        for itemProvider in attachments {
            itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                if let url = (item as? NSURL), let absoluteURL = url.absoluteURL {
                    if let urlID = self.extractVideoID(from: absoluteURL.absoluteString) {
                        if let url = URL(string: "cartube://\(urlID)") {
                            self.open(url: url)
                        }
                    } else {
                        if let url = URL(string: "cartube://") {
                            self.open(url: url)
                        }
                    }
                    self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                }
            }
        }
    }

    private func open(url: URL) {
        var responder: UIResponder? = self as UIResponder
        let selector = #selector(openURL(_:))

        while responder != nil {
            if responder!.responds(to: selector), responder != self {
                responder!.perform(selector, with: url)

                return
            }

            responder = responder?.next
        }
    }
    
    func extractVideoID(from link: String) -> String? {
        let regex = try! NSRegularExpression(pattern: "(?:youtube(?:-nocookie)?\\.com\\/(?:[^\\/\\n\\s]+\\/\\S+\\/|(?:v|e(?:mbed)?)\\/|\\S*?[?&]v=)|youtu\\.be\\/)([a-zA-Z0-9_-]{11})")
        guard let match = regex.firstMatch(in: link, range: NSRange(link.startIndex..., in: link)) else { return nil }
        guard let range = Range(match.range(at: 1), in: link) else { return nil }
        return String(link[range])
    }

    @objc
    private func openURL(_: URL) {}

    override func isContentValid() -> Bool {
        true
    }

    override func didSelectPost() {
        openExtensionContextURLs()
        extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func configurationItems() -> [Any]! {
        []
    }
}
