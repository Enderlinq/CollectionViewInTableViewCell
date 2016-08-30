//
//  DataSources.swift
//
//  The MIT License (MIT)
//
//  Created by mrandall on 8/27/15..
//  Copyright © 2015 mrandall. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

//MARK: - DataSourceDelegate

public protocol DataSourceDelegate: NSObjectProtocol {
    
    // Return a unique cellReuseIdentifier
    //
    // - Parameter dataSource: DataSource
    // - Parameter cellReuseIdentifierForIndexPath: NSIndexPath
    // - Parameter data: AnyObject
    //
    // - Return String
    func dataSource(dataSource: DataSource, cellReuseIdentifierForIndexPath: NSIndexPath, data: Any) -> String?
}

extension DataSourceDelegate {
    
    func dataSource(dataSource: DataSource, cellReuseIdentifierForIndexPath: NSIndexPath, data: AnyObject) -> String? {
        return nil
    }
}

//MARK: - DataSource

///Datasource Base Class
public class DataSource: NSObject {
    
    ///Set to any object you want UITableView or UICollectionView delegate methods forwarded to if concrete implimentations do not respond to them
    public weak var fallBackDataSource: AnyObject?

    weak var delegate: DataSourceDelegate?
    
    public override func respondsToSelector(aSelector: Selector) -> Bool {
        
        if let fallBackDataSource = self.fallBackDataSource {
            if (fallBackDataSource.respondsToSelector(aSelector)) {
                return true
            }
        }
        
        return super.respondsToSelector(aSelector)
    }
    
    public override func forwardingTargetForSelector(aSelector: Selector) -> AnyObject? {
        
        if let fallBackDataSource = self.fallBackDataSource {
            if (fallBackDataSource.respondsToSelector(aSelector)) {
                return fallBackDataSource
            }
        }
        
        return super.forwardingTargetForSelector(aSelector)
    }
}