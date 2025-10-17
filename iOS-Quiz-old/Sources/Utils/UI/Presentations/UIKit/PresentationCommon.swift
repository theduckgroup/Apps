import UIKit

/// Default presentation animator
public class DefaultPresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let animated: Bool
    
    init(animated: Bool) {
        self.animated = animated
    }
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        animated ? 0.35 : 0
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        let containerView = transitionContext.containerView
        
        let animationDuration = transitionDuration(using: transitionContext)
        
        containerView.addSubview(toViewController.view)
        
        UIView.animate(withDuration: animationDuration, animations: { () -> Void in
            // toViewController.view.transform = CGAffineTransformIdentity
            
        }, completion: { finished in
            transitionContext.completeTransition(finished)
        })
    }
}

/// Default dismissal animator
public class DefaultDismissalAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let animated: Bool
    
    init(animated: Bool) {
        self.animated = animated
    }
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        animated ? 0.3 : 0
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let animationDuration = transitionDuration(using: transitionContext)
        
        UIView.animate(withDuration: animationDuration, animations: { () -> Void in
            
        }, completion: { finished in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
