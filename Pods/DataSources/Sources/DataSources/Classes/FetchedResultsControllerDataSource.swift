//
//  FetchedResultsControllerDataSource.swift
//
//  The MIT License (MIT)
//
//  Created by mrandall on 10/17/15..
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
import CoreData

//MARK: - NSFetchedResultsControllerDataSource

//NOTE: FetchedResultsControllerDataSource subclasses don't support FRC with a section param
open class FetchedResultsControllerDataSource<T: NSFetchRequestResult, U>: DataSource,
    SectionDataSource,
    SectionDataSourceData
{

    ///ComponentDataSource section index
    open var sectionIndex = 0

    ///reusableIdentifier to dequeue the cell
    fileprivate let cellReuseIdentifier: String

    ///closure called to configure a cell on creation
    fileprivate var cellConfiguration: ((_ cell: U, _ indexPath: IndexPath, _ data: T) -> ())?

    //fileprivate var cellModelDataMap: CellModelDataMap?

    ///FetchedResultsController for section
    fileprivate var fetchedResultsController: NSFetchedResultsController<T>

    //MARK: - Init

    public typealias CellConfiguration = (_ cell: U, _ indexPath: IndexPath, _ data: T) -> Void

    //TODO: 9/19 updates NSFetchedResultsController broke this functionality
    //
    //Map NSManagedObject to other date type (T)
    //public typealias CellModelDataMap = (_ model: NSManagedObject) -> T

    //Number of FRC.fetchedObjects.count
    //Can be used to determine number of results or if dataSource has zero objects
    open var fetchedObjectsCount: Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }

    /// Init
    ///
    /// - Parameter data: T
    /// - Parameter cellIdentifier: String for the reusableIdentifier used to dequeue a cell
    /// - Parameter cellModelDataMap: CellModelDataMap
    /// - Parameter cellConfiguration: (cell: U, indexPath: NSIndexPath, data: T) closure is called for each cell created
    public init(
        fetchedResultsController: NSFetchedResultsController<T>,
        cellReuseIdentifier: String,
        //cellModelDataMap: CellModelDataMap? = nil,
        cellConfiguration: ((_ cell: U, _ indexPath: IndexPath, _ data: T) -> ())?

        ) {
        self.fetchedResultsController = fetchedResultsController
        self.cellReuseIdentifier = cellReuseIdentifier
        //self.cellModelDataMap = cellModelDataMap
        self.cellConfiguration = cellConfiguration
    }

    //MARK: - Data

    open func getDataAsAny(forIndexPath indexPath: IndexPath) -> Any {
        return getData(forIndexPath: indexPath) as Any
    }

    /// Provide data for cell indexPath
    /// Method will map return type using cellModelDataMap if it is set
    ///
    /// - Parameter indexPath: NSIndexPath of the cell
    /// - Returns T
    open func getData(forIndexPath indexPath: IndexPath) -> T {
        let managedObject = fetchedResultsController.object(at: IndexPath(row: (indexPath as NSIndexPath).row, section: 0))

//        //map date or convert to T
//        let data: T
//        if let map = cellModelDataMap {
//            data = map(model: managedObject as! NSManagedObject)
//        } else {
//            data = managedObject as! T
//        }

        return managedObject as T
    }
}

open class TableViewFetchedResultsControllerDataSource<T: NSFetchRequestResult, U>:
    FetchedResultsControllerDataSource<T, U>,
    UITableViewDataSource,
    NSFetchedResultsControllerDelegate

{

    //UITableView reference used by NSFetchedResultsControllerDelegate
    open weak var tableView: UITableView?


    /// Init
    ///
    /// - Parameter tableView: UITableView
    /// - Parameter data: T
    /// - Parameter cellIdentifier: String for the reusableIdentifier used to dequeue a cell
    /// - Parameter cellModelDataMap: CellModelDataMap
    /// - Parameter cellConfiguration: (cell: U, indexPath: NSIndexPath, data: T) closure is called for each cell created
    public init(
        tableView: UITableView,
        fetchedResultsController: NSFetchedResultsController<T>,
        cellReuseIdentifier: String,
        //cellModelDataMap: CellModelDataMap? = nil,
        cellConfiguration: CellConfiguration?
        ) {

        self.tableView = tableView
        super.init(
            fetchedResultsController: fetchedResultsController,
            cellReuseIdentifier: cellReuseIdentifier,
            //cellModelDataMap: cellModelDataMap,
            cellConfiguration: cellConfiguration)
        self.fetchedResultsController.delegate = self
    }

    //Mark: - UITableViewDataSource

    open func numberOfSections(in tableView: UITableView) -> Int {
        return 1 //TODO
    }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if let sections = self.fetchedResultsController.sections {

            //if sectionIndex is greater than zero SectionDataSource usage is assumed to be true
            if sectionIndex > 0 {
                let currentSection = sections[0]
                return currentSection.numberOfObjects

                //if seciontIndex is zero user FRC section
            } else {
                let currentSection = sections[section]
                return currentSection.numberOfObjects
            }
        }

        //default to zero
        return 0
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let data = getData(forIndexPath: indexPath)
        let cellReuseIdentifier = delegate?.dataSource(self, cellReuseIdentifierForIndexPath: indexPath, data: data as AnyObject) ?? self.cellReuseIdentifier
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)

        if let cellConfiguration = self.cellConfiguration {
            cellConfiguration(cell as! U, indexPath, data)
        }

        return cell
    }

    //Mark: - NSFetchedResultsControllerDelegate

    open func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView?.beginUpdates()
    }

    open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

        guard let tableView = self.tableView else { return }

        //Offset for sectionIndex
        let indexPathWithOffset = IndexPath(row: (indexPath as NSIndexPath?)?.row ?? 0, section: ((indexPath as NSIndexPath?)?.section ?? 0) + sectionIndex)
        let newIndexPathWithOffset = IndexPath(row: (newIndexPath as NSIndexPath?)?.row ?? 0, section: ((newIndexPath as NSIndexPath?)?.section ?? 0) + sectionIndex)

        switch type {

        case .insert:
            tableView.insertRows(at: [newIndexPathWithOffset], with: .fade)

        case .update:
            if let cell = tableView.cellForRow(at: indexPathWithOffset), let cellConfiguration = self.cellConfiguration {

                //map date or convert to T
//                let data: T
//                if let map = cellModelDataMap {
//                    data = map(model: anObject as! NSManagedObject)
//                } else {
//                    data = anObject as! T
//                }
//
                cellConfiguration(cell as! U, indexPathWithOffset, anObject as! T)
            }
            tableView.reloadRows(at: [indexPathWithOffset], with: .none)

        case .move:
            tableView.deleteRows(at: [indexPathWithOffset], with: .fade)
            tableView.insertRows(at: [newIndexPathWithOffset], with: .fade)

        case .delete:
            tableView.deleteRows(at: [indexPathWithOffset], with: .fade)
        }
    }

    open func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView?.endUpdates()
    }
}

open class CollectionViewFetchedResultsControllerDataSource<T: NSFetchRequestResult, U>:
    FetchedResultsControllerDataSource<T, U>,
    UICollectionViewDataSource,
    NSFetchedResultsControllerDelegate
{

    //UITableView reference used by NSFetchedResultsControllerDelegate
    open weak var collectionView: UICollectionView?

    /// Init
    ///
    /// - Parameter collectionView: UICollectionView
    /// - Parameter data: T
    /// - Parameter cellIdentifier: String for the reusableIdentifier used to dequeue a cell
    /// - Parameter cellModelDataMap: CellModelDataMap
    /// - Parameter cellConfiguration: (cell: U, indexPath: NSIndexPath, data: T) closure is called for each cell created
    public init(
        collectionView: UICollectionView,
        fetchedResultsController: NSFetchedResultsController<T>,
        cellReuseIdentifier: String,
        //cellModelDataMap: CellModelDataMap? = nil,
        cellConfiguration: CellConfiguration?
        ) {

        self.collectionView = collectionView
        super.init(
            fetchedResultsController: fetchedResultsController,
            cellReuseIdentifier: cellReuseIdentifier,
            //cellModelDataMap: cellModelDataMap,
            cellConfiguration: cellConfiguration)
        self.fetchedResultsController.delegate = self
    }

    //Mark: - UITableViewDataSource

    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let sections = self.fetchedResultsController.sections {
            let currentSection = sections[section]
            return currentSection.numberOfObjects
        }

        return 0
    }

    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let data = getData(forIndexPath: indexPath)
        let cellReuseIdentifier = delegate?.dataSource(self, cellReuseIdentifierForIndexPath: indexPath, data: data as AnyObject) ?? self.cellReuseIdentifier

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath)

        if let cellConfiguration = self.cellConfiguration {
            cellConfiguration(cell as! U, indexPath, data)
        }

        return cell
    }

    //Mark: - NSFetchedResultsControllerDelegate

    open func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.collectionView?.reloadData()
    }
}

#endif
