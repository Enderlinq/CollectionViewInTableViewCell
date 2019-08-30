//
//  ContentCategoryViewModel.swift
//  NetflixPOC
//
//  Created by mrandall on 8/26/16.
//
//

import Foundation
import RxSwift

public struct VideoCellData {
    
    private let video: Video
    
    var videoPosterImageURL: URL {
        return video.videoPosterURL
    }
    
    init(video: Video) {
        self.video = video
    }
}

public protocol VideoCategoryViewModelProtocol {
    
    var viewState: Observable<(String, [VideoCellData])> { get }
    func videoSelected(withIndex index: Int, tappedFrame: CGRect)
}

final class VideoCategoryViewModel: VideoCategoryViewModelProtocol {
    
    let videoSelected = PublishSubject<(Video, CGRect)>()
    var viewState: Observable<(String, [VideoCellData])>

    private let videos: [Video]

    // MARK: - Int
    
    init(title: String, videos: [Video]) {
        self.videos = videos
        let videosData = videos.map { VideoCellData(video: $0) }
        viewState = Observable.just((title, videosData))
    }
    
    // MARK: - Actions
    
    func videoSelected(withIndex index: Int, tappedFrame: CGRect) {
        videoSelected.onNext((videos[index], tappedFrame))
    }
}
