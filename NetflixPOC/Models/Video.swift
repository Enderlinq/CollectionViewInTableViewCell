//
//  Video.swift
//  NetflixPOC
//
//  Created by Mark Randall on 8/30/19.
//

import Foundation

/// Imagine this is a real model
public struct Video {
    
    var videoPosterURL: URL
    
    init() {

        let width = (arc4random_uniform(8) + 1) * 100;
        let height = (arc4random_uniform(8) + 1) * 100;
        videoPosterURL = URL(string: "https://www.fillmurray.com/\(width)/\(height)")!
    }
    
    
}
