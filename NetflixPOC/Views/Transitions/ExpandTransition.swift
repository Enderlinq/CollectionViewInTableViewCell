//
//  ExpandTransition.swift
//  NetflixPOC
//
//  Created by mrandall on 8/26/16.
//
//

import UIKit

final class ExpandTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    private let presenting: Bool
    private let presentingControlFrame: CGRect
    
    // Init
    //
    // - Parameter presenting: Bool
    init(presenting: Bool = true, presentingControlFrame: CGRect = .zero) {
        self.presenting = presenting
        self.presentingControlFrame = presentingControlFrame
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return (presenting) ? 0.7 : 0.4
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard
            let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
            else {
                assertionFailure("NavDrawerTransitionManager failed")
                transitionContext.completeTransition(false)
                return
        }
        
        let containerView = transitionContext.containerView
        let viewToAnimate: UIView
        let toFrame: CGRect
        
        if presenting == true {
            viewToAnimate = toViewController.view
            containerView.addSubview(viewToAnimate)
            viewToAnimate.frame = presentingControlFrame
            toFrame = transitionContext.finalFrame(for: toViewController)
        } else {
            viewToAnimate = fromViewController.view
            var frame = viewToAnimate.frame
            frame.origin.y = viewToAnimate.frame.size.height
            toFrame = frame
        }
        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0.0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0.5,
            options: (presenting == true) ? [.curveEaseOut] : [.curveEaseIn],
            animations: {
                viewToAnimate.frame = toFrame
                
                if self.presenting == false {
                    viewToAnimate.alpha = 0.0
                }
                
            }, completion: { finished in
                
                if self.presenting == false {
                    viewToAnimate.removeFromSuperview()
                }
                
                transitionContext.completeTransition(true)
        })
    }
}

