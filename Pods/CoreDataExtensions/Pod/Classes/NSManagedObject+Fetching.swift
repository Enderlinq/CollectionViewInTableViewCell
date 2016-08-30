//
//  NSManagedObject+Fetching.swift
//  CoreData2
//
//  Created by mrandall on 10/12/15.
//  Copyright © 2015 mrandall. All rights reserved.
//

import Foundation
import CoreData

//MARK: - Creating

public extension NSManagedObject {
    
    /// Create Self entity name in NSManagedObjectContext
    ///
    /// parameter moc: NSManagedObjectContext
    /// returns String
    public class func entityNameInContext(moc: NSManagedObjectContext) -> String {
        let classString = NSStringFromClass(self)
        let components = NSStringFromClass(self).componentsSeparatedByString(".")
        return components.last ?? classString
    }

    /// Create Self in NSManagedObjectContext
    ///
    /// parameter: moc NSManagedObjectContext
    public class func createInContext(moc: NSManagedObjectContext) -> Self {
        return _createInContext(moc, type: self)
    }
    
    /// Create Self in NSManagedObjectContext
    ///
    /// parameter moc: NSManagedObjectContext
    /// parameter type: Class
    /// return type
    private class func _createInContext<T>(moc: NSManagedObjectContext, type: T.Type) -> T {
        let entityName = entityNameInContext(moc)
        let entity = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: moc)
        return entity as! T
    }
}

//MARK: - Fetching

public extension NSManagedObject {
    
    /// Fetch all entities of type T
    ///
    /// parameter sort: [NSSortDescriptor]
    /// parameter moc: NSManagedObjectContext
    public class func fetchAll<T>(sortOn sort: [NSSortDescriptor]? = nil, moc: NSManagedObjectContext) -> [T] {
        return self.fetchWithPredicate(nil, sort: sort, prefetchRelationships: nil, moc: moc)
    }
    
    /// Fetch entities of type T
    ///
    /// NOTE: Current the return type must be specified where method is called to satisfy T.
    ///       Hopefully there is a better way in the future of Swift. [Self] is not allowed outside protocol definition
    ///
    /// parameter predicate: NSPredicate
    /// parameter sort: [NSSortDescriptor]
    /// parameter prefetchRelationships: [String] relationshipKeyPathsForPrefetching value
    /// parameter moc: NSManagedObjectContext
    public class func fetchWithPredicate<T>(
        predicate: NSPredicate?,
        sort: [NSSortDescriptor]? = [],
        prefetchRelationships: [String]? = nil,
        moc: NSManagedObjectContext
    ) -> [T] {
        
        //create fetchRequest
        let entityName = self.entityNameInContext(moc)
        let request = NSFetchRequest(entityName: entityName)
        request.predicate = predicate
        request.sortDescriptors = sort
        request.relationshipKeyPathsForPrefetching = prefetchRelationships
        
        //execute fetch
        do {
            return try moc.executeFetchRequest(request).map { return $0 as! T }
        } catch {
            return []
        }
    }
}