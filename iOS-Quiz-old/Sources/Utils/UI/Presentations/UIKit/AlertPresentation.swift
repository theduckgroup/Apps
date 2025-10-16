import UIKit

/// A transitioning delegate that presents and dismisses a view controller with animation and layout
/// similar to iOS's built-in alerts.
///
/// Example:
/// ```
/// class MyViewController: UIViewController {
///   let transitioningDelegateStrongRef = AlertTransitioningDelegate()
///
///   init() {
///     modalPresentationStyle = .custom
///     transitioningDelegate = transitioningDelegateStrongRef
///   }
/// }
/// ```
///
/// Note that you have to retain transitioning delegate yourself because `transitioningDelegate`
/// is weak ref.
public class AlertTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    public let animated: Bool
    public let offset: CGPoint
    
    /// Initialize
    ///
    /// - Important: ``UIViewController/transitioningDelegate`` is weakly referenced. You must retain this somewhere else.
    public init(animated: Bool = true, offset: CGPoint = .zero) {
        self.animated = animated
        self.offset = offset
        
        super.init()
    }
    
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let controller = PresentationController(presentedViewController: presented, presenting: presenting)
        controller.offset = offset
        
        return controller
    }
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        DefaultPresentationAnimator(animated: animated)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        DefaultDismissalAnimator(animated: animated)
    }
}

// MARK: - Presentation controller

private class PresentationController: UIPresentationController {
    private var dimView: UIView!
    
    var offset: CGPoint = CGPoint.zero
    
    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        
        dimView = UIView()
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        
        /*
        dimView.handleTap { [weak self] in
            self?.presentingViewController.dismiss(animated: true, completion: nil)
        }
        */
    }
    
    override var shouldPresentInFullscreen : Bool {
        return false
    }
    
    override func presentationTransitionWillBegin() {
        let containerView = self.containerView!
        
        // Dim view
        dimView.frame = containerView.bounds
        dimView.alpha = 0
        containerView.insertSubview(dimView, at: 0)
        
        let animated = presentedViewController.transitionCoordinator?.isAnimated ?? true
        
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { (coordinatorContext) -> Void in
            self.dimView.alpha = 1
            
        }, completion: nil)
        
        // Fade in
        let presentedView = self.presentedView!
        presentedView.frame = frameOfPresentedViewInContainerView
        presentedView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        presentedView.alpha = 0
        
        UIView.animate(withDuration: animated ? 0.35 : 0, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIView.AnimationOptions(), animations: { () -> Void in
            presentedView.transform = CGAffineTransform.identity
            presentedView.alpha = 1
            
        }, completion: nil)
    }
    
    override func dismissalTransitionWillBegin() {
        let animated = presentedViewController.transitionCoordinator?.isAnimated ?? true
        
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { (coordinatorContext) -> Void in
            self.dimView.alpha = 0
        }, completion: nil)
        
        // Slide down
        let presentedView = self.presentedView!
        presentedView.frame = frameOfPresentedViewInContainerView
        
        UIView.animate(withDuration: animated ? 0.5 : 0, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIView.AnimationOptions(), animations: { () -> Void in
            presentedView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            presentedView.alpha = 0
            
        }, completion: nil)
    }
    
    override func containerViewWillLayoutSubviews() {
        dimView.frame = containerView!.bounds
        
        let desiredFrame = frameOfPresentedViewInContainerView
        
        presentedView?.frame = desiredFrame
        
        if let presentedViewController = presentedViewController as? WidthConstrainedSizing {
            presentedViewController.constrainWidth(to: desiredFrame.width)
        }
    }
    
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        let containerView = self.containerView!
        let minHeight: CGFloat = 150
        let maxHeight = parentSize.height * 0.67
        
        if let z = presentedViewController as? WidthConstrainedSizing {
            let minWidth = max(parentSize.width * 0.33, 300)
            let maxWidth = parentSize.width - 40
            
            
            // Find the width that will yield width-height ratio closest to golden
            var bestGoodness: CGFloat = CGFloat.infinity
            var bestSize: CGSize = CGSize.zero

            let steps = 20
            for i in 0 ... steps {
                let width = minWidth + (maxWidth - minWidth) * CGFloat(i) / CGFloat(steps)
                
                var size = z.preferredSize(withConstrainedWidth: width)
                size.height = size.height.clamped(to: minHeight...maxHeight) // Constrain height within screen
                
                let ratio = width / size.height
                
                let goodness = abs(ratio - 1.61) / 1.61
                
                if goodness < bestGoodness {
                    bestGoodness = goodness
                    bestSize = size
                }
            }
            
            return bestSize
            
        } else {
            var size = presentedViewController.preferredContentSize

            size.width = min(size.width, containerView.frame.width - 40)
            size.height = min(size.height, parentSize.height * 0.66)
            
            return size
        }
    }
    
    override var frameOfPresentedViewInContainerView : CGRect {
        let bounds = containerView!.bounds
        
        let contentContainer = presentedViewController
        
        let sz = size(forChildContentContainer: contentContainer, withParentContainerSize: bounds.size)
        
        var rect = CGRect(
            x: bounds.width / 2 - sz.width / 2 + offset.x,
            y: bounds.height / 2 - sz.height / 2 + offset.y,
            width: sz.width,
            height: sz.height)
        
        if rect.origin.y < 30 {
            rect.origin.y = 40
        }
        
        return rect
    }
}
