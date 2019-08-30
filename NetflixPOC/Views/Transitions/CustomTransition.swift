//
//  CustomTransition.swift
//  NetflixPOC
//
//  Created by Mark Randall on 8/30/19.
//

import Foundation
import UIKit

final class CustomTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
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
        return (presenting) ? 1.0 : 0.4
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
       
        // Image / top half
        let viewToAnimate: UIView
        let toFrame: CGRect
        
        // Content / bottom half
        var viewToAnimate2: UIView?
        let toFrame2: CGRect?
        
        if presenting == true {
            
            viewToAnimate = fromViewController.view.resizableSnapshotView(from: presentingControlFrame, afterScreenUpdates: false, withCapInsets: .zero) ?? UIView()
            containerView.addSubview(viewToAnimate)
            viewToAnimate.frame = presentingControlFrame
            let toWidth = transitionContext.finalFrame(for: toViewController).size.width
            toFrame = CGRect(x: 0, y: 0, width: toWidth, height: toWidth)
            
            containerView.addSubview(toViewController.view)
            viewToAnimate2 = toViewController.view.resizableSnapshotView(from: toViewController.view.bounds, afterScreenUpdates: true, withCapInsets: .zero)!
            toViewController.view.removeFromSuperview()
            
            viewToAnimate2?.frame = presentingControlFrame
            containerView.insertSubview(viewToAnimate2!, belowSubview: viewToAnimate)
            viewToAnimate2!.alpha = 0.0
            toFrame2 = transitionContext.finalFrame(for: toViewController)
            
        } else {
            viewToAnimate = fromViewController.view
            var frame = viewToAnimate.frame
            frame.origin.y = viewToAnimate.frame.size.height
            toFrame = frame
            
            viewToAnimate2 = nil
            toFrame2 = nil
        }
        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0.0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: (presenting == true) ? [.curveEaseOut] : [.curveEaseIn],
            animations: {
                viewToAnimate.frame = toFrame
                viewToAnimate2!.alpha = 1.0
                viewToAnimate2?.frame = toFrame2 ?? .zero
                
                if !self.presenting {
                    viewToAnimate.alpha = 0.0
                }
                
        }, completion: { finished in
            
            containerView.addSubview(toViewController.view)
            viewToAnimate.removeFromSuperview()
            viewToAnimate2?.removeFromSuperview()
            
            transitionContext.completeTransition(true)
        })
    }
}


