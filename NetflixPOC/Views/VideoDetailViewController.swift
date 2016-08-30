//
//  VideoDetailViewController.swift
//  NetflixPOC
//
//  Created by mrandall on 8/26/16.
//
//

import UIKit
import PINRemoteImage

final class VideoDetailViewController: UIViewController {

    
    //MARK: - ViewModel
    
    var viewModel: VideoViewModel?
    
    
    //MARK: - Subviews
    
    @IBOutlet private var posterImageView: UIImageView! {
        didSet {
            posterImageView.pin_updateWithProgress = true
        }
    }
    
    
    //MARK: - UIViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        defer {
            bindViewModel()
        }
    }

    
    //MARK: - Bind ViewModel
    
    private func bindViewModel() {

        posterImageView.pin_setImageFromURL(viewModel?.posterURL)
    }
}
