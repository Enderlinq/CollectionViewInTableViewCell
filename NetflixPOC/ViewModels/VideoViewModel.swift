//
//  VideoViewModel.swift
//  NetflixPOC
//
//  Created by mrandall on 8/26/16.
//
//

import Foundation


//MARK: VideoViewModel public interface

public protocol IVideoViewModel {
    
    //Video poster image URL
    var posterURL: NSURL { get }
}


//MARK: VideoViewModel

//Data for individual Video
final class VideoViewModel: IVideoViewModel {
    
    private(set) var posterURL: NSURL
    
    init(video: String) {
        
        //fake video URL
        let width = (arc4random_uniform(8) + 1) * 100;
        let height = (arc4random_uniform(8) + 1) * 100;
        posterURL = NSURL(string: "https://www.fillmurray.com/\(width)/\(height)")!
    }
}