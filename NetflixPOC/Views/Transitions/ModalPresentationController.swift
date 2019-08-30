//
//  ModalPresentationController.swift
//
//  Created by mrandall on 11/25/15.
//  Copyright © 2015 The Nerdery. All rights reserved.
//

import UIKit

@objc
protocol ModalPresentationControllerDelegate: NSObjectProtocol {
    
    @objc optional
    func overlayWasTappedForModal(modal: ModalPresentationController )
    
    @objc optional
    func overlayWasSwippedLeftForModal(modal: ModalPresentationController )
    
    @objc optional
    func overlayWasSwippedDownForModal(modal: ModalPresentationController )
}

enum ModalTransitionControllerLayout {
    case center
    case upperRight
}

final class ModalPresentationController: UIPresentationController {
    
    weak var modalDelegate: ModalPresentationControllerDelegate?
    
    var layout: ModalTransitionControllerLayout =  .center
    
    lazy var chromeView: UIView = { [unowned self] in
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0.0
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(chromeViewTapped(recognizer:)))
        view.addGestureRecognizer(tapGestureRecognizer)
        
        return view
    }()
    
    override var frameOfPresentedViewInContainerView: CGRect {
        
        guard presentedViewController.preferredContentSize != .zero else {
            return presentingViewController.view.bounds
        }
        
        let marginW : CGFloat
        let marginH: CGFloat
        if layout == .center {
            marginW = (self.containerView!.bounds.size.width - presentedViewController.preferredContentSize.width) / 2.0
            marginH = (self.containerView!.bounds.size.height - presentedViewController.preferredContentSize.height) / 2.0
        } else {
            marginW = 0.0
            marginH = 0.0
        }
        
        return CGRect(x: marginW, y: marginH, width: presentedViewController.preferredContentSize.width, height: presentedViewController.preferredContentSize.height)
    }
    
    override func presentationTransitionWillBegin() {
        
        if let containerView = containerView {
            chromeView.frame = containerView.bounds
            containerView.addSubview(chromeView)
        }
        
        //theme
        presentedView?.layer.shadowColor = UIColor(0x2a2a29).cgColor
        presentedView?.layer.shadowRadius = 5
        presentedView?.layer.shadowOpacity = 0.42
        
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.chromeView.alpha = 0.7
        }) { _ in }
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        
        if completed == false {
            
            chromeView.gestureRecognizers?.forEach {
                chromeView.removeGestureRecognizer($0)
            }
            
            chromeView.removeFromSuperview()
        }
        
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipedLeftToClose(recognizer:)))
        swipeGestureRecognizer.direction = .left
        chromeView.addGestureRecognizer(swipeGestureRecognizer)
        
        let swipeDownGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipedDownToClose(recognizer:)))
        swipeDownGestureRecognizer.direction = .down
        chromeView.addGestureRecognizer(swipeDownGestureRecognizer)
    }
    
    override func dismissalTransitionWillBegin() {
        
        chromeView.gestureRecognizers?.forEach {
            chromeView.removeGestureRecognizer($0)
        }
        
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { (context) in
            self.chromeView.alpha = 0.0
            }) { (context) in }
    }
    
//    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
//
//        guard presentingViewController.preferredContentSize != .zero else {
//            return presentingViewController.view.bounds.size
//        }
//
//        return presentedViewController.preferredContentSize
//    }
//
//    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
//        var frame = self.presentedViewController.view.frame
//        frame.size = self.presentedViewController.preferredContentSize
//        presentedViewController.view.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
//    }
    
    //MARK: - Actions
    
    @objc func chromeViewTapped(recognizer: UITapGestureRecognizer) {
        modalDelegate?.overlayWasTappedForModal?(modal: self)
    }
    
    @objc func swipedLeftToClose(recognizer: UISwipeGestureRecognizer) {
        modalDelegate?.overlayWasSwippedLeftForModal?(modal: self)
    }
    
    @objc func swipedDownToClose(recognizer: UISwipeGestureRecognizer) {
        modalDelegate?.overlayWasSwippedDownForModal?(modal: self)
    }
}
