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

public struct FeaturedContentTableViewCellIdentifiers {
    static let CategoryCell = "ContentCategoryTableViewCell"
    static let VideoCell = "VideoCollectionViewCell"
}

final class FeaturedContentViewController: UITableViewController {
    
    
    //MARK: - ViewModel
    
    private let disposeBag = DisposeBag()
    
    //TODO: Create elsewhere in the future / inject
    lazy var viewModel: IFeaturedVideosViewModel = FeaturedVideosViewModel()
    
    
    //MARK: - DataSource
    
    private var dataSource: UITableViewDataSource?
    
    
    //MARK: - UIViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        defer {
            bindViewModel()
        }
        
        //configure UITableView
        tableView.registerNib(UINib(nibName: "VideoCategoryTableViewCell", bundle: nil), forCellReuseIdentifier: FeaturedContentTableViewCellIdentifiers.CategoryCell)
        //tableView.separatorStyle = .None
        tableView.estimatedRowHeight = 100.0
    }
    
    
    //MARK: - Bind ViewModel

    private func bindViewModel() {
        
        viewModel.videoCategories.subscribeNext { [weak self] videoCategories in
 
            self?.dataSource = ArrayDataSource(
                data: videoCategories,
                cellReuseIdentifier: FeaturedContentTableViewCellIdentifiers.CategoryCell
            ) { (cell: VideoCategoryTableViewCell, _, data: IVideoCategoryViewModel) in
                cell.viewModel =  data
            }
            
            self?.tableView.dataSource = self?.dataSource
            self?.tableView.reloadData()
            
        }.addDisposableTo(disposeBag)
        
        viewModel.showVideoDetail.subscribeNext { [weak self] in
            self?.performSegueWithIdentifier(Segue.ShowVideoDetail, sender: $0 as? AnyObject)
        }.addDisposableTo(disposeBag)
    }
    
    
    //MARK: - Navigation
    
    @IBAction private func unwindFromVideoDetail(sender: UIStoryboardSegue) {}
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == Segue.ShowVideoDetail {
            
            guard
                let viewModel = sender as? VideoViewModel,
                let nc = segue.destinationViewController as? UINavigationController,
                let vc = nc.topViewController as? VideoDetailViewController
            else {
                assertionFailure("Segue 'ShowVideoDetail' is not properly configured")
                return
            }
            
            nc.transitioningDelegate = self
            nc.modalPresentationStyle = .Custom
            vc.viewModel = viewModel
        }
    }
}


//MARK: - UIViewControllerTransitioningDelegate

extension FeaturedContentViewController: UIViewControllerTransitioningDelegate {
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let frame = viewModel.lastFrameTappedToShowViewDetail ?? CGRectZero
        return ExpandVideoTransition(presentingControlFrame: frame)
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ExpandVideoTransition(presenting: false)
    }
    
    func presentationControllerForPresentedViewController(presented: UIViewController, presentingViewController presenting: UIViewController, sourceViewController source: UIViewController) -> UIPresentationController? {
        let presentationController = ModalPresentationController(presentedViewController: presented, presentingViewController: presenting)
        presentationController.layout = .UpperRight
        return presentationController
    }
}
