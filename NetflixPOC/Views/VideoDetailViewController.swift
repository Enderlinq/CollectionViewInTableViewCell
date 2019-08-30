//
//  VideoDetailViewController.swift
//  NetflixPOC
//
//  Created by mrandall on 8/26/16.
//
//

import UIKit
import PINRemoteImage
import RxSwift

final class VideoDetailViewController: UIViewController {

    private var viewModel: VideoDetailViewModelProtocol?
    private var disposeBag = DisposeBag()
    
    // MARK: - Subviews
    
    @IBOutlet private var posterImageView: UIImageView!
    
    @IBOutlet private var closeButon: UIButton! {
        didSet {
            closeButon.layer.cornerRadius = 22
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Incase view wasn't loaded when bind was called
        // TODO: improve. Results in binding twice
        if let viewModel = self.viewModel {
            bind(viewModel: viewModel)
        }
    }
    
    // MARK: - Bind ViewModel
    
    func bind(viewModel: VideoDetailViewModelProtocol) {
        
        self.viewModel = viewModel
        
        guard viewIfLoaded != nil else { return }
        
        disposeBag = DisposeBag()
        
        viewModel.viewState.subscribe(onNext: { [weak self] viewState in
            self?.posterImageView.pin_setImage(from: viewState)
        }).disposed(by: disposeBag)
    }
}
