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

#if canImport(UIKit)

import UIKit

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
open class AlphabeticallySectionedArrayDataSource<T: Equatable, U>:
    DataSource,
    UITableViewDataSource,
    SectionDataSourceData
{

    ///reusableIdentifier to dequeue the cell
    let cellReuseIdentifier: String

    ///closure called to configure a cell on creation
    var cellConfiguration: ((_ cell: U, _ indexPath: IndexPath, _ data: T) -> ())?

    //MARK - Partitioned Data

    open var data: [T] {
        didSet {
            sectionedData = createParitionedData()
        }
    }

    fileprivate var sectionedData = [Section<T>]()

    fileprivate let sectionedValueMap: (T) -> String

    open var showSectionIndexTitles = false

    //MARK: - Init

    public typealias CellConfiguration = (_ cell: U, _ indexPath: IndexPath, _ data: T) -> Void

    /// Init
    ///
    /// - Parameter data: T
    /// - Parameter cellIdentifier: String for the reusableIdentifier used to dequeue a cell
    /// - Parameter cellConfiguration: (cell: U, indexPath: NSIndexPath, data: T) closure is called for each cell created
    public init(
        data: [T],
        cellReuseIdentifier: String,
        cellConfiguration: CellConfiguration?,
        sectionedValueMap: @escaping (T) -> String
        ) {
        self.data = data
        self.cellReuseIdentifier = cellReuseIdentifier
        self.cellConfiguration = cellConfiguration
        self.sectionedValueMap = sectionedValueMap
        super.init()
        self.sectionedData = createParitionedData()
    }

    //MARK: - Partition data

    fileprivate func createParitionedData() -> [Section<T>] {
        let titles = UILocalizedIndexedCollation.current().sectionTitles
        return titles.reduce([Section]()) { (reduced: [Section], title) in

            var reduced = reduced

            let firstLetter = String(describing: title.first).lowercased()
            let rows = data.filter {
                String(describing: sectionedValueMap($0).first).lowercased() == firstLetter
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
    open func getData(forIndexPath indexPath: IndexPath) -> T {
        return sectionedData[(indexPath as NSIndexPath).section].rows[(indexPath as NSIndexPath).row]
    }

    /// Attempt to determine indexPath for value of type T
    ///
    /// - Parameter forData: T
    /// - Return NSIndexPath?
    open func getIndexPath(forData data: T) -> IndexPath? {


        let displayValue = sectionedValueMap(data)
        let displayValueFirstLetter = (displayValue as NSString).substring(to: 1).uppercased()
        guard let section = sectionedData
            .map({ $0.title })
            .index(where: { $0 == displayValueFirstLetter
            }) else { return nil }
        let sectionData = sectionedData[section].rows
        guard let row = sectionData.index(where: { (rowData: T) -> Bool in rowData == data }) else { return nil }
        return IndexPath(row: row, section: section)
    }

    //MARK: - UITableViewDataSource

    open func numberOfSections(in tableView: UITableView) -> Int {
        return sectionedData.count
    }

    open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionedData[section].title
    }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionedData[section].rows.count
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let data = getData(forIndexPath: indexPath)
        let cellReuseIdentifier = delegate?.dataSource(self, cellReuseIdentifierForIndexPath: indexPath, data: data as AnyObject) ?? self.cellReuseIdentifier

        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)

        if let cellConfiguration = cellConfiguration {
            cellConfiguration(cell as! U, indexPath, data)
        }

        return cell
    }

    open func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        guard showSectionIndexTitles == true else { return [] }
        return sectionedData.map { return $0.title }
    }

    open func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
}

#endif
