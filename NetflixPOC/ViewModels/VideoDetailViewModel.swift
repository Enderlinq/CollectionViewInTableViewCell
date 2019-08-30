//
//  VideoDetailViewModel.swift
//  NetflixPOC
//
//  Created by Mark Randall on 8/30/19.
//

import Foundation
import RxSwift

public protocol VideoDetailViewModelProtocol {
    
    var viewState: Observable<URL> { get }
}

final class VideoDetailViewModel: VideoDetailViewModelProtocol {
    
    let viewState: Observable<URL>
    
    init(video: Video) {
        viewState = Observable.just(video.videoPosterURL)
    }
}
