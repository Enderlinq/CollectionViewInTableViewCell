//
// Created by Joshua Sullivan on 8/26/15.
// Copyright (c) 2015 Nerdery, LLC. All rights reserved.
//

import UIKit

public extension UIColor {

    /// Convience initializer.
    ///
    /// ```swift
    /// UIColor(0xFF0000)
    /// ```
    /// - Parameter rgbHex: Hex value
    /// - Returns: An initialized color object
    convenience init(_ rgbHex: UInt) {
        self.init(rgbHex, alpha: 1.0)
    }

    /// Convience initializer.
    ///
    /// ```swift
    /// UIColor(0xFF0000, alpha: 1.0)
    /// ```
    ///
    /// - Parameter rgbHex: Hex value
    /// - Parameter alpha: The opacity value of the color object, specified as a value from 0.0 to 1.0.
    /// - Returns: An initialized color object
    convenience init(_ rgbHex: UInt, alpha: CGFloat) {
        let rawRed = CGFloat((rgbHex >> 16) & 0xFF) / 255.0
        let rawGreen = CGFloat((rgbHex >> 8) & 0xFF) / 255.0
        let rawBlue = CGFloat(rgbHex & 0xFF) / 255.0
        self.init(red: rawRed, green: rawGreen, blue: rawBlue, alpha: alpha)
    }
}

