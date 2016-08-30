//
//  ModalPresentationController.swift
//
//  Created by mrandall on 11/25/15.
//  Copyright © 2015 The Nerdery. All rights reserved.
//

import UIKit

@objc
protocol ModalPresentationControllerDelegate: NSObjectProtocol {
    
    optional
    func overlayWasTappedForModal(modal: ModalPresentationController )
    
    optional
    func overlayWasSwippedLeftForModal(modal: ModalPresentationController )
    
    optional
    func overlayWasSwippedDownForModal(modal: ModalPresentationController )
}

private struct ControllerSelector {
    static let ChromeViewTapped = #selector(ModalPresentationController.chromeViewTapped(_:))
    static let SwippedLeftToClose = #selector(ModalPresentationController.swipedLeftToClose(_:))
    static let SwippedDownToClose = #selector(ModalPresentationController.swipedDownToClose(_:))
}

enum ModalTransitionControllerLayout {
    case Center
    case UpperRight
}

final class ModalPresentationController: UIPresentationController {
    
    weak var modalDelegate: ModalPresentationControllerDelegate?
    
    var layout: ModalTransitionControllerLayout =  .Center
    
    lazy var chromeView: UIView = { [unowned self] in
        let view = UIView()
        view.backgroundColor = UIColor.blackColor()
        view.alpha = 0.0
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: ControllerSelector.ChromeViewTapped)
        view.addGestureRecognizer(tapGestureRecognizer)
        
        return view
    }()
    
    override func presentationTransitionWillBegin() {
        
        if let containerView = containerView {
            chromeView.frame = containerView.bounds
            containerView.addSubview(chromeView)
        }
        
        //theme
        presentedView()?.layer.shadowColor = UIColor(0x2a2a29).CGColor
        presentedView()?.layer.shadowRadius = 5
        presentedView()?.layer.shadowOpacity = 0.42
        
        presentedViewController.transitionCoordinator()?.animateAlongsideTransition({ (context) in
            self.chromeView.alpha = 0.7
            }) { (context) in }
    }
    
    override func presentationTransitionDidEnd(completed: Bool) {
        if completed == false {
            
            chromeView.gestureRecognizers?.forEach {
                chromeView.removeGestureRecognizer($0)
            }
            
            chromeView.removeFromSuperview()
        }
        
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: ControllerSelector.SwippedLeftToClose)
        swipeGestureRecognizer.direction = .Left
        chromeView.addGestureRecognizer(swipeGestureRecognizer)
        
        let swipeDownGestureRecognizer = UISwipeGestureRecognizer(target: self, action: ControllerSelector.SwippedDownToClose)
        swipeDownGestureRecognizer.direction = .Down
        chromeView.addGestureRecognizer(swipeDownGestureRecognizer)
    }
    
    override func dismissalTransitionWillBegin() {
        
        chromeView.gestureRecognizers?.forEach {
            chromeView.removeGestureRecognizer($0)
        }
        
        presentedViewController.transitionCoordinator()?.animateAlongsideTransition({ (context) in
            self.chromeView.alpha = 0.0
            }) { (context) in }
    }
    
    override func sizeForChildContentContainer(container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        
        guard presentingViewController.preferredContentSize != CGSizeZero else {
            return presentingViewController.view.bounds.size
        }
        
        return presentedViewController.preferredContentSize
    }
    
    override func preferredContentSizeDidChangeForChildContentContainer(container: UIContentContainer) {
        var frame = self.presentedViewController.view.frame
        frame.size = self.presentedViewController.preferredContentSize
        presentedViewController.view.frame = frame
    }
    
    override func frameOfPresentedViewInContainerView() -> CGRect {
        
        guard presentingViewController.preferredContentSize != CGSizeZero else {
            return presentingViewController.view.bounds
        }
        
        let marginW : CGFloat
        let marginH: CGFloat
        if layout == .Center {
            marginW = (self.containerView!.bounds.size.width - presentedViewController.preferredContentSize.width) / 2.0
            marginH = (self.containerView!.bounds.size.height - presentedViewController.preferredContentSize.height) / 2.0
        } else {
            marginW = 0.0
            marginH = 0.0
        }
        
        return CGRectMake(marginW, marginH, presentedViewController.preferredContentSize.width, presentedViewController.preferredContentSize.height)
    }
    
    //MARK: - Actions
    
    func chromeViewTapped(recognizer: UITapGestureRecognizer) {
        modalDelegate?.overlayWasTappedForModal?(self)
    }
    
    func swipedLeftToClose(recognizer: UISwipeGestureRecognizer) {
        modalDelegate?.overlayWasSwippedLeftForModal?(self)
    }
    
    func swipedDownToClose(recognizer: UISwipeGestureRecognizer) {
        modalDelegate?.overlayWasSwippedDownForModal?(self)
    }
}
