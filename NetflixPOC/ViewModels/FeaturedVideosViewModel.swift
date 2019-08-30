//
//  FeaturedVideosViewModel.swift
//  NetflixPOC
//
//  Created by mrandall on 8/26/16.
//
//

import Foundation
import RxSwift


// MARK: FeaturedContentViewModel public interface

public protocol FeaturedVideosViewModelProtocol {

    var viewState: Observable<[VideoCategoryViewModelProtocol]> { get }
    var showVideoDetail: Observable<(VideoDetailViewModelProtocol, CGRect)> { get }
}


// MARK: FeaturedContentViewModel

// Feature video content sections data
//
// Responsible for:
// - requesting VideoCateory models from API client
// - mapping VideoCategory model to IVideoCategoryViewModel to expose to View layer
//
final class FeaturedVideosViewModel: FeaturedVideosViewModelProtocol {
 
    
    // MARK: - Data
 
    private let _viewState = Variable([VideoCategoryViewModelProtocol]())
    var viewState: Observable<[VideoCategoryViewModelProtocol]> { return _viewState.asObservable() }
    
    
    // MARK: - Navigation
    
    private let _showVideoDetail = PublishSubject<(VideoDetailViewModelProtocol, CGRect)>()
    var showVideoDetail: Observable<(VideoDetailViewModelProtocol, CGRect)> { return _showVideoDetail.asObservable() }
    
    
    // MARK: - Init
    
    private var disposeBag = DisposeBag()
    
    init() {
        let data: [[Video]] = (0..<9).map { _ in (0..<9).map { _ in Video() } } // Fake data
        updateWithModel(data: data)
    }
    
    // MARK: - Update with model
    
    private func updateWithModel(data: [[Video]]) {
        
        //map models to viewModels
        //set delegate to allow view model created by self to message self
        let nextVideoCategories: [VideoCategoryViewModel] = data.map { videos in
            VideoCategoryViewModel(title: "testing", videos: videos)
        }
        
        // Observe video category videoSelected
        disposeBag = DisposeBag()
        Observable.merge(nextVideoCategories.map({ $0.videoSelected })).subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            let presentationRect = $0.1
            let video = $0.0
            let detailVM = VideoDetailViewModel(video: video)
            self._showVideoDetail.onNext((detailVM, presentationRect))
        }).disposed(by: disposeBag)
        
        _viewState.value = nextVideoCategories
    }
}
