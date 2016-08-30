//
//  ContentCategoryTableViewCell.swift
//  NetflixPOC
//
//  Created by mrandall on 8/26/16.
//
//

import UIKit
import RxSwift
import DataSources

final class VideoCategoryTableViewCell: UITableViewCell {

    
    //MARK: - ViewModel
    
    var viewModel: IVideoCategoryViewModel? {
        didSet {
            bindViewModel()
        }
    }
    
    private var disposeBag = DisposeBag()
    
    
    //MARK: - DataSource
    
    private var dataSource: UICollectionViewDataSource?
    
    
    //MARK: - Layout
    
    var videoItemSize: CGSize = CGSize(width: 100.0, height: 100.0)
    var videoItemMargin = 10.0
    
    
    //MARK: - Subviews
    
    @IBOutlet private var titleLabel: UILabel!
    
    @IBOutlet private var collectionView: UICollectionView! {
        didSet {
            collectionView.registerNib(UINib(nibName: "VideoCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: FeaturedContentTableViewCellIdentifiers.VideoCell)
            collectionView.backgroundColor = UIColor.whiteColor()
            collectionView?.delegate = self
        }
    }
    
    
    //MARK: - UITableViewCell Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        defer {
            bindViewModel()
        }
        
        selectionStyle = .None
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        //re-set disposebag to nil existing bag to dispose existing disposibles / bindings
        disposeBag = DisposeBag()
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        collectionView?.heightAnchor.constraintEqualToConstant(videoItemSize.height + CGFloat(videoItemMargin * 2.0)).active = true
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize =  videoItemSize
            layout.scrollDirection = .Horizontal
            layout.minimumInteritemSpacing = CGFloat(videoItemMargin)
            layout.sectionInset = UIEdgeInsets(
                top: CGFloat(videoItemMargin / 2.0),
                left: CGFloat(videoItemMargin),
                bottom: CGFloat(videoItemMargin / 2.0),
                right: CGFloat(videoItemMargin)
            )
        }
    }
    
    
    //MARK: - Bind ViewModel
        
    private func bindViewModel() {
    
        guard let viewModel = self.viewModel else {
            return
        }
        
        viewModel.title.subscribeNext { [weak self] title in
            self?.titleLabel.text = title
        }.addDisposableTo(disposeBag)
        
        viewModel.videos.subscribeNext { [weak self] videos in
            
            self?.dataSource = ArrayDataSource(
                data: videos,
                cellReuseIdentifier: FeaturedContentTableViewCellIdentifiers.VideoCell
            ) { (cell: VideoCollectionViewCell, _, data: IVideoViewModel) in
                cell.viewModel =  data
            }
            
            self?.collectionView.dataSource = self?.dataSource
            self?.collectionView.reloadData()
            
        }.addDisposableTo(disposeBag)
    }
}


//MARK: - UICollectionViewDelegate

extension VideoCategoryTableViewCell: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        //get frame
        let attributes = collectionView.layoutAttributesForItemAtIndexPath(indexPath)
        var frame = attributes?.frame ?? CGRectZero
        
        //convert frame to superview coord ctx
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        frame = cell?.superview?.convertRect(frame, toView: nil) ?? CGRectZero
        
        viewModel?.videoSelected(withIndex: indexPath.row, tappedFrame: frame ?? CGRectZero)
    }
}
