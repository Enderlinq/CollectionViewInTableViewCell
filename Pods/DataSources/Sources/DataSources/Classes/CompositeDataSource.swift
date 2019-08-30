//
//  CompositeDataSources.swift
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

#if canImport(UIKit)

import UIKit

public protocol SectionDataSource {

    ///section individual data source is used populate
    ///Required for NSFetchedResultsController driven ComponentDataSource data sources
    var sectionIndex: Int { get set }

    /// Provide data for cell indexPath as Any
    ///
    /// CompositeDataSource can support return a generic and
    /// SectionDataSourceData can't be cast to a SectionDataSourceData because it is a associated type protocol
    /// The work around was this method. Caller is responsible for casting to T where necessary
    ///
    /// - Parameter indexPath: NSIndexPath of the cell
    /// - Returns Any
    func getDataAsAny(forIndexPath indexPath: IndexPath) -> Any
}

public protocol SectionDataSourceData {

    associatedtype T

    /// Provide data for cell indexPath
    ///
    /// - Parameter indexPath: NSIndexPath of the cell
    /// - Returns T
    func getData(forIndexPath indexPath: IndexPath) -> T
}

///Allows multiple SectionDataSource to be composed using one per section
open class CompositeDataSource: DataSource, UITableViewDataSource, UICollectionViewDataSource {

    ///Data sources used per section
    open var dataSourcesPerSection: [SectionDataSource] = [] {
        didSet {
            var i = 0
            for var ds in self.dataSourcesPerSection {
                ds.sectionIndex = i
                i = i + 1
            }
            ///self.dataSourcesPerSection.forEach { $0.sectionIndex = ++i }
        }
    }

    //MARK: - Init

    public init(dataSourcesPerSection: [SectionDataSource]) {

        super.init()

        //wrap in defer to call dataSourcesPerSection didSet observer
        defer {
            self.dataSourcesPerSection = dataSourcesPerSection
        }
    }


    //MARK: - Data

    open func getDataAsAny(forIndexPath indexPath: IndexPath) -> Any? {
        guard dataSourcesPerSection.count > (indexPath as NSIndexPath).section else { return nil }
        return dataSourcesPerSection[(indexPath as NSIndexPath).section].getDataAsAny(forIndexPath: indexPath)
    }


    //MARK: - UITableViewDataSource

    open func numberOfSections(in tableView: UITableView) -> Int { return self.dataSourcesPerSection.count }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        //check to ensure any dataSourcesPerSection is not empty array if so return 0
        guard dataSourcesPerSection.count > section else { return 0 }

        let dataSourcePerSection = dataSourcesPerSection[section] as! UITableViewDataSource
        return dataSourcePerSection.tableView(tableView, numberOfRowsInSection: section)
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dataSourcePerSection = self.dataSourcesPerSection[(indexPath as NSIndexPath).section] as! UITableViewDataSource
        return dataSourcePerSection.tableView(tableView, cellForRowAt: indexPath)
    }

    //MARK - UICollectionViewDataSource

    open func numberOfSections(in collectionView: UICollectionView) -> Int { return self.dataSourcesPerSection.count }

    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let dataSourcePerSection = self.dataSourcesPerSection[section] as! UICollectionViewDataSource
        return dataSourcePerSection.collectionView(collectionView, numberOfItemsInSection: section)
    }

    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dataSourcePerSection = self.dataSourcesPerSection[(indexPath as NSIndexPath).section] as! UICollectionViewDataSource
        return dataSourcePerSection.collectionView(collectionView, cellForItemAt: indexPath)
    }
}

#endif
