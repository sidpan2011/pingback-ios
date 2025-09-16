import UIKit
import SwiftUI
import Social
import Foundation
import MobileCoreServices

class ShareViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("🚀 Share Extension: Loading SwiftUI interface")
        
        // Create SwiftUI view
        let shareView = ShareExtensionView()
        let hostingController = UIHostingController(rootView: shareView)
        
        // Add as child view controller
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        hostingController.didMove(toParent: self)
        
        // Pass extension context to SwiftUI view
        ExtensionContext.shared = extensionContext
    }
}

// MARK: - Extension Context Sharing

class ExtensionContext: ObservableObject {
    static var shared: NSExtensionContext?
}
