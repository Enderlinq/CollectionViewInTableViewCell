//
//  FeaturedVideosViewModel.swift
//  NetflixPOC
//
//  Created by mrandall on 8/26/16.
//
//

import Foundation
import RxSwift


//MARK: FeaturedContentViewModel public interface

public protocol IFeaturedVideosViewModel {

    //Video categories
    var videoCategories: Observable<[IVideoCategoryViewModel]> { get }
    
    //Navigate to a VideoDetail screen
    var showVideoDetail: Observable<IVideoViewModel> { get }
    
    //CGRect of a view's subview which was interacted with the cause showVideoDetail to be emitted
    //Useful for custom transitions
    var lastFrameTappedToShowViewDetail: CGRect? { get }
}


//MARK: FeaturedContentViewModel

//Feature video content sections data
//
//Responsible for:
//- requesting VideoCateory models from API client
//- mapping VideoCategory model to IVideoCategoryViewModel to expose to View layer
//
final class FeaturedVideosViewModel: IFeaturedVideosViewModel {
 
    
    //MARK: - Data
 
    private let _videoCategories = BehaviorSubject(value: [IVideoCategoryViewModel]())
    var videoCategories: Observable<[IVideoCategoryViewModel]> { return _videoCategories.asObservable() }
    
    
    //MARK: - Navigation
    
    private let _showVideoDetail = PublishSubject<IVideoViewModel>()
    var showVideoDetail: Observable<IVideoViewModel> { return _showVideoDetail.asObservable() }
    
    private(set) var lastFrameTappedToShowViewDetail: CGRect?
    
    
    //MARK: - Init
    
    init() {
        
        //Will be replaced with NSManagedObject models
        let data = [
            ["a", "b", "c", "d", "e", "f", "g", "h"],
            ["a", "b", "c", "d", "e", "f", "g", "h"],
            ["a", "b", "c", "d", "e", "f", "g", "h"],
            ["a", "b", "c", "d", "e", "f", "g", "h"],
            ["a", "b", "c", "d", "e", "f", "g", "h"],
            ["a", "b", "c", "d", "e", "f", "g", "h"],
            ["a", "b", "c", "d", "e", "f", "g", "h"],
            ["a", "b", "c", "d", "e", "f", "g", "h"],
            ["a", "b", "c", "d", "e", "f", "g", "h"],
            ["a", "b", "c", "d", "e", "f", "g", "h"],
            ["a", "b", "c", "d", "e", "f", "g", "h"],
            ["a", "b", "c", "d", "e", "f", "g", "h"]
        ]
        
        updateWithModel(data)
    }
    
    
    //MARK: - Update with model
    
    private func updateWithModel(data: [[String]]) {
        
        //map models to viewModels
        //set delegate to allow view model created by self to message self
        let nextVideoCategories: [IVideoCategoryViewModel] = data.map { videos in
            let vm = VideoCategoryViewModel(title: "testing", videos: videos)
            vm.delegate = self
            return vm
        }
        
        //TODO: could diff current videoCategory value and nextVideoCategories to provide update methods
        
        _videoCategories.onNext(nextVideoCategories)
    }
}


//MARK: - ContentCategoryViewModelProtocol

extension FeaturedVideosViewModel: VideoCategoryViewModelProtocol {
    
    func contentCategory(contentCategory: IVideoCategoryViewModel, videoSelected video: IVideoViewModel, tappedFrame tappedControlFrame: CGRect) {
        lastFrameTappedToShowViewDetail = tappedControlFrame //TODO: how to clean up
        _showVideoDetail.onNext(video)
    }
}