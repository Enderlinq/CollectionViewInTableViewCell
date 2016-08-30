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

import Foundation
import CoreData

//MARK: - NSFetchedResultsControllerDataSource

//NOTE: FetchedResultsControllerDataSource subclasses don't support FRC with a section param
public class FetchedResultsControllerDataSource<T, U>: DataSource,
    SectionDataSource,
    SectionDataSourceData
{
    
    ///ComponentDataSource section index
    public var sectionIndex = 0
    
    ///reusableIdentifier to dequeue the cell
    private let cellReuseIdentifier: String
    
    ///closure called to configure a cell on creation
    private var cellConfiguration: ((cell: U, indexPath: NSIndexPath, data: T) -> ())?
    
    private var cellModelDataMap: CellModelDataMap?
    
    ///FetchedResultsController for section
    private var fetchedResultsController: NSFetchedResultsController
    
    //MARK: - Init
    
    public typealias CellConfiguration = (cell: U, indexPath: NSIndexPath, data: T) -> Void
    
    //Map NSManagedObject to other date type (T)
    public typealias CellModelDataMap = (model: NSManagedObject) -> T
    
    //Number of FRC.fetchedObjects.count
    //Can be used to determine number of results or if dataSource has zero objects
    public var fetchedObjectsCount: Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    /// Init
    ///
    /// - Parameter data: T
    /// - Parameter cellIdentifier: String for the reusableIdentifier used to dequeue a cell
    /// - Parameter cellModelDataMap: CellModelDataMap
    /// - Parameter cellConfiguration: (cell: U, indexPath: NSIndexPath, data: T) closure is called for each cell created
    public init(
        fetchedResultsController: NSFetchedResultsController,
        cellReuseIdentifier: String,
        cellModelDataMap: CellModelDataMap? = nil,
        cellConfiguration: ((cell: U, indexPath: NSIndexPath, data: T) -> ())?
        
        ) {
        self.fetchedResultsController = fetchedResultsController
        self.cellReuseIdentifier = cellReuseIdentifier
        self.cellModelDataMap = cellModelDataMap
        self.cellConfiguration = cellConfiguration
    }
    
    //MARK: - Data
    
    public func getDataAsAny(forIndexPath indexPath: NSIndexPath) -> Any {
        return getData(forIndexPath: indexPath) as! Any
    }
    
    /// Provide data for cell indexPath
    /// Method will map return type using cellModelDataMap if it is set
    ///
    /// - Parameter indexPath: NSIndexPath of the cell
    /// - Returns T
    public func getData(forIndexPath indexPath: NSIndexPath) -> T {
        let managedObject = fetchedResultsController.objectAtIndexPath(NSIndexPath(forRow: indexPath.row, inSection: 0))
        
        //map date or convert to T
        let data: T
        if let map = cellModelDataMap {
            data = map(model: managedObject as! NSManagedObject)
        } else {
            data = managedObject as! T
        }
        
        return data
    }
}

public class TableViewFetchedResultsControllerDataSource<T, U>:
    FetchedResultsControllerDataSource<T, U>,
    UITableViewDataSource,
    NSFetchedResultsControllerDelegate
    
{
    
    //UITableView reference used by NSFetchedResultsControllerDelegate
    public weak var tableView: UITableView?
    
    
    /// Init
    ///
    /// - Parameter tableView: UITableView
    /// - Parameter data: T
    /// - Parameter cellIdentifier: String for the reusableIdentifier used to dequeue a cell
    /// - Parameter cellModelDataMap: CellModelDataMap
    /// - Parameter cellConfiguration: (cell: U, indexPath: NSIndexPath, data: T) closure is called for each cell created
    public init(
        tableView: UITableView,
        fetchedResultsController: NSFetchedResultsController,
        cellReuseIdentifier: String,
        cellModelDataMap: CellModelDataMap? = nil,
        cellConfiguration: CellConfiguration?
        ) {
        
        self.tableView = tableView
        super.init(
            fetchedResultsController: fetchedResultsController,
            cellReuseIdentifier: cellReuseIdentifier,
            cellModelDataMap: cellModelDataMap,
            cellConfiguration: cellConfiguration)
        self.fetchedResultsController.delegate = self
    }
    
    //Mark: - UITableViewDataSource
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1 //TODO
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
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
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let data = getData(forIndexPath: indexPath)
        let cellReuseIdentifier = delegate?.dataSource(self, cellReuseIdentifierForIndexPath: indexPath, data: data as! AnyObject) ?? self.cellReuseIdentifier
        let cell = tableView.dequeueReusableCellWithIdentifier(cellReuseIdentifier, forIndexPath: indexPath)
        
        if let cellConfiguration = self.cellConfiguration {
            cellConfiguration(cell: cell as! U, indexPath: indexPath, data: data)
        }
        
        return cell
    }
    
    //Mark: - NSFetchedResultsControllerDelegate
    
    public func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView?.beginUpdates()
    }
    
    public func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        guard let tableView = self.tableView else { return }
        
        //Offset for sectionIndex
        var indexPathWithOffset = NSIndexPath(forRow: indexPath?.row ?? 0, inSection: (indexPath?.section ?? 0) + sectionIndex)
        var newIndexPathWithOffset = NSIndexPath(forRow: newIndexPath?.row ?? 0, inSection: (newIndexPath?.section ?? 0) + sectionIndex)
        
        switch type {
            
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPathWithOffset], withRowAnimation: .Fade)
            
        case .Update:
            if let cell = tableView.cellForRowAtIndexPath(indexPathWithOffset), let cellConfiguration = self.cellConfiguration {
                
                //map date or convert to T
                let data: T
                if let map = cellModelDataMap {
                    data = map(model: anObject as! NSManagedObject)
                } else {
                    data = anObject as! T
                }
                
                cellConfiguration(cell: cell as! U, indexPath: indexPathWithOffset, data: data)
            }
            tableView.reloadRowsAtIndexPaths([indexPathWithOffset], withRowAnimation: .None)
            
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPathWithOffset], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPathWithOffset], withRowAnimation: .Fade)
            
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPathWithOffset], withRowAnimation: .Fade)
        }
    }
    
    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView?.endUpdates()
    }
}

public class CollectionViewFetchedResultsControllerDataSource<T, U>: FetchedResultsControllerDataSource<T, U>, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    
    //UITableView reference used by NSFetchedResultsControllerDelegate
    public weak var collectionView: UICollectionView?
    
    /// Init
    ///
    /// - Parameter collectionView: UICollectionView
    /// - Parameter data: T
    /// - Parameter cellIdentifier: String for the reusableIdentifier used to dequeue a cell
    /// - Parameter cellModelDataMap: CellModelDataMap
    /// - Parameter cellConfiguration: (cell: U, indexPath: NSIndexPath, data: T) closure is called for each cell created
    public init(
        collectionView: UICollectionView,
        fetchedResultsController: NSFetchedResultsController,
        cellReuseIdentifier: String,
        cellModelDataMap: CellModelDataMap? = nil,
        cellConfiguration: CellConfiguration?
        ) {
        
        self.collectionView = collectionView
        super.init(
            fetchedResultsController: fetchedResultsController,
            cellReuseIdentifier: cellReuseIdentifier,
            cellModelDataMap: cellModelDataMap,
            cellConfiguration: cellConfiguration)
        self.fetchedResultsController.delegate = self
    }
    
    //Mark: - UITableViewDataSource
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let sections = self.fetchedResultsController.sections {
            let currentSection = sections[section]
            return currentSection.numberOfObjects
        }
        
        return 0
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let data = getData(forIndexPath: indexPath)
        let cellReuseIdentifier = delegate?.dataSource(self, cellReuseIdentifierForIndexPath: indexPath, data: data as! AnyObject) ?? self.cellReuseIdentifier
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellReuseIdentifier, forIndexPath: indexPath)
        
        if let cellConfiguration = self.cellConfiguration {
            cellConfiguration(cell: cell as! U, indexPath: indexPath, data: data)
        }
        
        return cell
    }
    
    //Mark: - NSFetchedResultsControllerDelegate
    
    public func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.collectionView?.reloadData()
    }
}
