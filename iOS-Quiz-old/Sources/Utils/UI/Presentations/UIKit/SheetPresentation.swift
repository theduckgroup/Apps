import UIKit

/// Transitioning delegate that presents view controller in a manner similar to action sheet (from bottom of screen).
///
/// ``UIViewController/transitioningDelegate`` is weak ref. You are responsible for keeping the delegate alive by other means.
public class SheetTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    public let animated: Bool
    
    /// Creates an instance.
    ///
    /// - Important: ``UIViewController/transitioningDelegate`` is weakly referenced. You must retain this by other means.
    public init(animated: Bool = true) {
        self.animated = animated
        
        super.init()
    }
    
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        PresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        DefaultPresentationAnimator(animated: animated)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        DefaultDismissalAnimator(animated: animated)
    }
}

private var keepAlivePool: [AnyObject] = []

// MARK: - Presentation controller

private class PresentationController: UIPresentationController {
    private var dimView: UIView!
    
    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        
        dimView = UIView()
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }
    
    override var shouldPresentInFullscreen : Bool {
        return true
    }
    
    override func presentationTransitionWillBegin() {
        let containerView = self.containerView!
        
        // Dim view
        dimView.frame = containerView.bounds
        dimView.alpha = 0
        containerView.insertSubview(dimView, at: 0)
        
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { (coordinatorContext) -> Void in
            self.dimView.alpha = 1
            
        }, completion: nil)
        
        // Slide up
        let presentedView = self.presentedView!
        presentedView.frame = frameOfPresentedViewInContainerView
        presentedView.transform = CGAffineTransform(translationX: 0, y: presentedView.frame.height)
        
        // let springParams = UISpringTimingParameters(mass: 0.01, stiffness: 10, damping: 1, initialVelocity: CGVector(dx: 0.5, dy: 0))
        let springParams = UISpringTimingParameters(dampingRatio: 10)
        
        let animator = UIViewPropertyAnimator(duration: 0.4, timingParameters: springParams)
        
        animator.addAnimations {
            presentedView.transform = CGAffineTransform.identity
        }
        
        animator.startAnimation()
    }
    
    override func dismissalTransitionWillBegin() {
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { (coordinatorContext) -> Void in
            self.dimView.alpha = 0
        }, completion: nil)
        
        // Slide down
        // Note: putting inside the above `animte(alongsideTransition:)` causes animation glitch
        // Also presentedViewController.transitionCoordinator!.transitionDuration is always 0
        let presentedView = self.presentedView!
        presentedView.frame = frameOfPresentedViewInContainerView
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: []) {
            presentedView.transform = CGAffineTransform(translationX: 0, y: presentedView.frame.height + 20) // 20 to accommodate for the gap when horizontal size class is Regular
            
        } completion: { finished in
            
        }
    }
    
    override func containerViewWillLayoutSubviews() {
        dimView.frame = containerView!.bounds
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
    
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        let window = containerView!.window ?? UIApplication.shared.anyKeyWindow
        let isCompact = window?.traitCollection.horizontalSizeClass == .compact
        
        let containerView = self.containerView!
        
        func preferredHeightForViewController(_ viewController: UIViewController, thatFitsWidth width: CGFloat) -> CGFloat {
            if let fs = viewController as? WidthConstrainedSizing {
                return fs.preferredSize(withConstrainedWidth: width).height
                
            } else {
                return viewController.preferredContentSize.height
            }
        }
        
        if isCompact {
            let width = containerView.frame.width
            
            var presentedHeight = preferredHeightForViewController(presentedViewController, thatFitsWidth: width)
            let containerSafeHeight = containerView.frame.height - containerView.safeAreaInsets.top - containerView.safeAreaInsets.bottom
            
            if presentedHeight > containerSafeHeight {
                presentedHeight = containerSafeHeight
            }
            
            // presentedHeight += containerView.safeAreaInsets.bottom // Add extra height to cover bottom safe area

            return CGSize(width: width, height: presentedHeight)
            
        } else {
            let width = containerView.frame.width * 2 / 3
            
            var presentedHeight = preferredHeightForViewController(presentedViewController, thatFitsWidth: width)
            presentedHeight = min(presentedHeight, containerView.frame.height * 2 / 3)
            
            return CGSize(width: width, height: presentedHeight)
        }
    }
    
    override var frameOfPresentedViewInContainerView : CGRect {
        let window = containerView!.window ?? UIApplication.shared.anyKeyWindow
        let isCompact = window?.traitCollection.horizontalSizeClass == .compact
        
        let bounds = containerView!.bounds
        let contentContainer = presentedViewController
        let sz = self.size(forChildContentContainer: contentContainer, withParentContainerSize: bounds.size)
        
        if isCompact {
            // Fill the bottom
            return CGRect(
                x: 0,
                y: bounds.height - sz.height,
                width: sz.width,
                height: sz.height
                ).integral
            
        } else {
            // Centered bottom
            return CGRect(
                x: bounds.width / 2 - sz.width / 2,
                y: bounds.height - sz.height - 20,
                width: sz.width,
                height: sz.height
                ).integral
        }
    }
    
    @objc private func handleTap(_ g: UITapGestureRecognizer) {
        presentingViewController.dismiss(animated: true, completion: nil)
    }
}
