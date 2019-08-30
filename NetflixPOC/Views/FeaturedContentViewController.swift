//
//  ViewController.swift
//  NetflixPOC
//
//  Created by mrandall on 8/26/16.
//
//

import UIKit
import RxSwift
import DataSources

private struct Segue {
    static let ShowVideoDetail = "ShowVideoDetail"
}

final class FeaturedContentViewController: UITableViewController {
    
    lazy var viewModel: FeaturedVideosViewModelProtocol = FeaturedVideosViewModel()
    private let disposeBag = DisposeBag()

    private var dataSource: RxDataSource<VideoCategoryViewModelProtocol, VideoCategoryTableViewCell>?
    
    // Frame of seleced cell
    // Frame transition is expanding from
    private var lastFrameTappedToShowViewDetail: CGRect?
    
    // MARK: - UIViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        defer { bindViewModel() }
        
        // configure UITableView
        tableView.separatorStyle = .none
        tableView.rowHeight = 160
    }
    
    // MARK: - Bind ViewModel

    private func bindViewModel() {
        
        dataSource = tableView.create(observable: viewModel.viewState)

        viewModel.showVideoDetail.subscribe(onNext: { [weak self] in
            self?.performSegue(withIdentifier: Segue.ShowVideoDetail, sender: $0)
        }).disposed(by: disposeBag)
    }
    
    // MARK: - Navigation
    
    @IBAction private func unwindFromVideoDetail(sender: UIStoryboardSegue) {
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Segue.ShowVideoDetail {
            
            guard
                let viewModelAndFrame = sender as? (VideoDetailViewModelProtocol, CGRect),
                let nc = segue.destination as? UINavigationController,
                let vc = nc.topViewController as? VideoDetailViewController
                else {
                    assertionFailure("Segue 'ShowVideoDetail' is not properly configured")
                    return
            }

            vc.bind(viewModel: viewModelAndFrame.0)
            
            // Set for custom UIViewControllerAnimatedTransitioning
            nc.transitioningDelegate = self
            
            // Transition doesn't work with .formSheet for some reason
            // Getting this to work with modalPresentationStyle = .custom may be desired
            // nc.modalPresentationStyle = .formSheet
            
            // Set for custom UIPresentationController
            nc.modalPresentationStyle = .custom
            //nc.navigationBar.clipsToBounds = true // Maybe a better solve for this
            
            // This .formsheet cheat is not working for CustomTransform.
            // Partly not respecting preferredContentSize. Partly not sure why
            // Looks good on an iPhones with notches for now :|
//            if self.traitCollection.horizontalSizeClass == .regular {
//                nc.preferredContentSize = view.bounds.insetBy(dx: 80, dy: 80).size
//            }
            
            lastFrameTappedToShowViewDetail = viewModelAndFrame.1
        }
    }
}

// MARK: - UIViewControllerTransitioningDelegate

extension FeaturedContentViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let frame = lastFrameTappedToShowViewDetail ?? .zero
        return CustomTransition(presentingControlFrame: frame)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ExpandTransition(presenting: false)
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let presentationController = ModalPresentationController(presentedViewController: presented, presenting: presenting)
        presentationController.layout = .center
        return presentationController
    }
}
