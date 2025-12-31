import Foundation
import UIKit
import SwiftUI

/// Controller that can be used for presenting SwiftUI view using alert transitioning delegate.
///
/// This implements alert transitioning delegate, fitting size and styling.
class AlertTransitioningHostingController<Content: View>: UIViewController {
    private let hostingController: UIHostingController<Content>
    private let transitioningDelegateRef: AlertTransitioningDelegate
    
    init(rootView: Content, offset: CGPoint = .zero) {
        // UIHostingController is added as a child controller
        // Using it directly (via inheritance) causes issue with sizing
        
        transitioningDelegateRef = .init(offset: offset)
        hostingController = UIHostingController(rootView: rootView)
        
        super.init(nibName: nil, bundle: nil)
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        modalPresentationStyle = .custom
        transitioningDelegate = transitioningDelegateRef
        
        view.backgroundColor = .white
        view.layer.cornerRadius = 30
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    deinit {} // Needed due to compiler error
    
    override var preferredContentSize: CGSize {
        get {
            hostingController.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        }
        set {}
    }
}
