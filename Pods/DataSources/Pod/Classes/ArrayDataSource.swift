//
//  ArrayDataSource.swift
//
//  The MIT License (MIT)
//
//  Created by mrandall on 10/27/15..
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

import Foundation

//MARK: - ArrayDataSource

//Array Datasource for a UITableView or a UICollectionView
public class ArrayDataSource<T, U>: DataSource,
    UITableViewDataSource,
    UICollectionViewDataSource,
    SectionDataSource,
    SectionDataSourceData
{
    
    ///reusableIdentifier to dequeue the cell
    let cellReuseIdentifier: String
    
    ///closure called to configure a cell on creation
    var cellConfiguration: ((cell: U, indexPath: NSIndexPath, data: T) -> ())?
    
    ///Data to display in tableview
    public var data: [T]
    
    ///ComponentDataSource section index
    public var sectionIndex = 0
    
    //MARK: - Init
    
    public typealias CellConfiguration = (cell: U, indexPath: NSIndexPath, data: T) -> Void
    
    /// Init
    ///
    /// - Parameter data: T
    /// - Parameter cellIdentifier: String for the reusableIdentifier used to dequeue a cell
    /// - Parameter cellConfiguration: (cell: U, indexPath: NSIndexPath, data: T) closure is called for each cell created
    public init(data: [T], cellReuseIdentifier: String, cellConfiguration: CellConfiguration?) {
        self.data = data
        self.cellReuseIdentifier = cellReuseIdentifier
        self.cellConfiguration = cellConfiguration
    }
    
    //MARK: - Data
    
    /// Provide data for cell indexPath
    ///
    /// - Parameter indexPath: NSIndexPath of the cell
    /// - Returns T for a give cell
    public func getData(forIndexPath indexPath: NSIndexPath) -> T {
        return data[indexPath.row]
    }
    
    public func getDataAsAny(forIndexPath indexPath: NSIndexPath) -> Any {
        return getData(forIndexPath: indexPath) as! Any
    }
    
    //MARK: - UITableViewDataSource
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let data: T = getData(forIndexPath: indexPath)
        let cellReuseIdentifier = delegate?.dataSource(self, cellReuseIdentifierForIndexPath: indexPath, data: data as! AnyObject) ?? self.cellReuseIdentifier
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellReuseIdentifier, forIndexPath: indexPath)
        
        if let cellConfiguration = cellConfiguration {
            cellConfiguration(cell: cell as! U, indexPath: indexPath, data: data)
        }
        
        return cell
    }
    
    //MARK: - UICollectionViewDataSource
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.data.count
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let data: T = getData(forIndexPath: indexPath)
        let cellReuseIdentifier = delegate?.dataSource(self, cellReuseIdentifierForIndexPath: indexPath, data: data as! AnyObject) ?? self.cellReuseIdentifier
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellReuseIdentifier, forIndexPath: indexPath)
        
        if let cellConfiguration = self.cellConfiguration {
            cellConfiguration(cell: cell as! U, indexPath: indexPath, data: data)
        }
        
        return cell
    }
}