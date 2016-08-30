//
//  ContentCategoryViewModel.swift
//  NetflixPOC
//
//  Created by mrandall on 8/26/16.
//
//

import Foundation
import RxSwift


//MARK: VideoCategoryViewModelProtocol

//Allows ContentCategoryViewModel to message parent ViewModel (FeaturedContentViewModel)
public protocol VideoCategoryViewModelProtocol: class {
    
    // Video was selected by user
    //
    // - parameter contentCategory: IVideoCategoryViewModel
    // - parameter video: IVideoModel
    // - parameter tappedFrame: CGRect - Frame of view tapped by user to select a video. Coordinate space is UIWindow.
    func contentCategory(contentCategory: IVideoCategoryViewModel, videoSelected video: IVideoViewModel, tappedFrame: CGRect)
}


//MARK: VideoCategoryViewModel public interface

public protocol IVideoCategoryViewModel {
    
    //Video category title
    var title: Observable<String> { get }
    
    //Video to display
    var videos: Observable<[IVideoViewModel]> { get }
    
    //Video at a specific index was selected by the suer
    //
    // - parameter withIndex: Int - Index of video in array of video models. Row of seleceted cell.
    // - parameter tappedFrame: CGRect - Frame tapped by the user
    func videoSelected(withIndex index: Int, tappedFrame: CGRect)
}


//MARK: ContentCategoryViewModel 

//Video category data
//
//Responsible for:
//- mapping Video model to IVideoViewModel to expose to View layer
//
final class VideoCategoryViewModel: IVideoCategoryViewModel {
    

    //MARK: - Delegate
    
    weak var delegate: VideoCategoryViewModelProtocol?
    
    
    //MARK: - Data
    
    private let  _title = BehaviorSubject(value: "")
    var title: Observable<String> { return _title.asObservable() }
    
    private let _videos = BehaviorSubject(value: [IVideoViewModel]())
    var videos: Observable<[IVideoViewModel]> { return _videos.asObservable() }


    //MARK: - Int
    
    init(title: String, videos: [String]) {

        _title.onNext(title)
        
        //map models to viewModels
        let nextVideos: [IVideoViewModel] = videos.map { video in
            VideoViewModel(video: video)
        }
        _videos.onNext(nextVideos)
    }
    
    
    //MARK: - Actions
    
    func videoSelected(withIndex index: Int, tappedFrame: CGRect) {

        _videos.subscribeNext { videos in
            self.delegate?.contentCategory(self, videoSelected: videos[index], tappedFrame: tappedFrame)
        }.dispose()
    }
}