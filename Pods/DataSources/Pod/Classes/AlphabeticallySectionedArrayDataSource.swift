//
//  AlphabeticallySectionedArrayDataSource.swift
//
//  The MIT License (MIT)
//
//  Created by mrandall on 1/31/16.
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
//

import Foundation

//MARK: - Section

struct Section<T: Equatable> {
    let title: String
    let rows: [T]
    
    init(title: String, rows: [T]) {
        self.title = title
        self.rows = rows
    }
}

//MARK: - AlphabeticallySectionedArrayDataSource

//Array Datasource for a UITableView which creates a section for each data strings first letter
public class AlphabeticallySectionedArrayDataSource<T: Equatable, U>:
    DataSource,
    UITableViewDataSource,
    SectionDataSourceData
{
    
    ///reusableIdentifier to dequeue the cell
    let cellReuseIdentifier: String
    
    ///closure called to configure a cell on creation
    var cellConfiguration: ((cell: U, indexPath: NSIndexPath, data: T) -> ())?
    
    //MARK - Partitioned Data
    
    public var data: [T] {
        didSet {
            sectionedData = createParitionedData()
        }
    }
    
    private var sectionedData = [Section<T>]()
    
    private let sectionedValueMap: (T) -> String
    
    public var showSectionIndexTitles = false
    
    //MARK: - Init
    
    public typealias CellConfiguration = (cell: U, indexPath: NSIndexPath, data: T) -> Void
    
    /// Init
    ///
    /// - Parameter data: T
    /// - Parameter cellIdentifier: String for the reusableIdentifier used to dequeue a cell
    /// - Parameter cellConfiguration: (cell: U, indexPath: NSIndexPath, data: T) closure is called for each cell created
    public init(
        data: [T],
        cellReuseIdentifier: String,
        cellConfiguration: CellConfiguration?,
        sectionedValueMap: (T) -> String
        ) {
        self.data = data
        self.cellReuseIdentifier = cellReuseIdentifier
        self.cellConfiguration = cellConfiguration
        self.sectionedValueMap = sectionedValueMap
        super.init()
        self.sectionedData = createParitionedData()
    }
    
    //MARK: - Partition data
    
    private func createParitionedData() -> [Section<T>] {
        let titles = UILocalizedIndexedCollation.currentCollation().sectionTitles
        return titles.reduce([Section]()) { (var reduced: [Section], title) in
            
            let firstLetter = String(title.characters.first).lowercaseString
            let rows = data.filter {
                String(sectionedValueMap($0).characters.first).lowercaseString == firstLetter
            }
            if rows.count > 0 {
                reduced.append(Section(title: title, rows: rows))
            }
            
            return reduced
        }
    }
    
    /// Get data at indexPath
    ///
    /// - Parameter atIndexPath: NSIndexPath
    /// - Return T
    public func getData(forIndexPath indexPath: NSIndexPath) -> T {
        return sectionedData[indexPath.section].rows[indexPath.row]
    }
    
    /// Attempt to determine indexPath for value of type T
    ///
    /// - Parameter forData: T
    /// - Return NSIndexPath?
    public func getIndexPath(forData data: T) -> NSIndexPath? {
        
        let displayValue = sectionedValueMap(data)
        let displayValueFirstLetter = displayValue.substringToIndex(displayValue.startIndex.advancedBy(1)).uppercaseString
        guard let section = sectionedData
            .map({ $0.title })
            .indexOf({ $0 == displayValueFirstLetter
            }) else { return nil }
        let sectionData = sectionedData[section].rows
        guard let row = sectionData.indexOf({ (rowData: T) -> Bool in rowData == data }) else { return nil }
        return NSIndexPath(forRow: row, inSection: section)
    }
    
    //MARK: - UITableViewDataSource
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionedData.count
    }
    
    public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionedData[section].title
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionedData[section].rows.count
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let data = getData(forIndexPath: indexPath)
        let cellReuseIdentifier = delegate?.dataSource(self, cellReuseIdentifierForIndexPath: indexPath, data: data as! AnyObject) ?? self.cellReuseIdentifier
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellReuseIdentifier, forIndexPath: indexPath)
        
        if let cellConfiguration = cellConfiguration {
            cellConfiguration(cell: cell as! U, indexPath: indexPath, data: data)
        }
        
        return cell
    }
    
    public func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        guard showSectionIndexTitles == true else { return [] }
        return sectionedData.map { return $0.title }
    }
    
    public func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return index
    }
}