//
//  VideoCollectionViewCell.swift
//  NetflixPOC
//
//  Created by mrandall on 8/26/16.
//
//

import UIKit
import PINRemoteImage

final class VideoCollectionViewCell: UICollectionViewCell, RxDataSourceCell {

    static var reuseIdentifier = "VideoCollectionViewCell"

    // MARK: - Subviews
    
    @IBOutlet private var posterImageView: UIImageView!
    
    // MARK: - UICollectionViewCell Lifecycle
    
    override func prepareForReuse() {
        super.prepareForReuse()
        posterImageView.pin_cancelImageDownload()
        posterImageView.image = nil
    }
    
    // MARK: - Bind ViewModel
    
    func bind(viewModel: VideoCellData) {
        posterImageView.pin_setImage(from: viewModel.videoPosterImageURL)
    }
}
