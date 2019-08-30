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

final class VideoCategoryTableViewCell: UITableViewCell, RxDataSourceCell {
    
    static var reuseIdentifier = "VideoCategoryTableViewCell"
    
    private var viewModel: VideoCategoryViewModelProtocol?
    private var disposeBag = DisposeBag()
    
    // MARK: - DataSource
    
    private var dataSource: RxDataSource<VideoCellData, VideoCollectionViewCell>?
    
    // MARK: - Subviews
    
    @IBOutlet private var titleLabel: UILabel!
    
    @IBOutlet private var collectionView: UICollectionView! {
        didSet {
            collectionView.backgroundColor = .white
            collectionView?.delegate = self
            (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection = .horizontal
        }
    }
    
    // MARK: - UITableViewCell Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    
    // MARK: - Bind ViewModel
        
    func bind(viewModel: VideoCategoryViewModelProtocol) {
    
        self.viewModel = viewModel
    
        // Dispose last binding. e.g. cell is being re-used
        disposeBag = DisposeBag()
                
        // Imagine this makes sense because a single TableViewCell could update
        // Also imagine a world where the dataSource.data updates the table without reloading
        viewModel.viewState.subscribe(onNext: { [weak self] viewState in
            self?.titleLabel.text = viewState.0
        }).disposed(by: disposeBag)
        
        dataSource = collectionView.create(observable: viewModel.viewState.map({ $0.1 }))
    }
}

// MARK: - UICollectionViewDelegate

extension VideoCategoryTableViewCell: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // get frame
        let attributes = collectionView.layoutAttributesForItem(at: indexPath)
        var frame = attributes?.frame ?? .zero
        
        // convert frame to superview coord ctx
        let cell = collectionView.cellForItem(at: indexPath)
        frame = cell?.superview?.convert(frame, to: nil) ?? .zero
        
        viewModel?.videoSelected(withIndex: indexPath.row, tappedFrame: frame)
    }
}
