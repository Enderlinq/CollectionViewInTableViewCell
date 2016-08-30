//
//  VideoCollectionViewCell.swift
//  NetflixPOC
//
//  Created by mrandall on 8/26/16.
//
//

import UIKit
import PINRemoteImage

final class VideoCollectionViewCell: UICollectionViewCell {

    
    //MARK: - ViewModel
    
    var viewModel: IVideoViewModel? {
        didSet {
            bindViewModel()
        }
    }
    
    
    //MARK: - Subviews
    
    @IBOutlet private var posterImageView: UIImageView! {
        didSet {
            posterImageView.pin_updateWithProgress = true
        }
    }
    
    
    //MARK: - UICollectionViewCell Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        posterImageView.image = nil
    }
    
    
    //MARK: - Bind ViewModel
    
    private func bindViewModel() {
        posterImageView.pin_setImageFromURL(viewModel?.posterURL)
    }
}
