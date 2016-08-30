//
//  NSManagedObjectModel+Enums.swift
//  CoreData2
//
//  Created by mrandall on 10/15/15.
//  Copyright © 2015 mrandall. All rights reserved.
//

import Foundation
import CoreData

public extension NSManagedObjectModel {
    
    public func printEntityAttributeAndRelationshipStructs() {
        
        for entity in self.entities {
            
            print("-----------------")
            print(entity.name!)
            print("-----------------")
            
            print("")
            
            print("struct \(entity.name!)Attribute {")
            let sortedAttributeKeys = entity.attributesByName.keys.sort {
                $0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending
            }
            for attributeName in sortedAttributeKeys {
                print("\tstatic let \(attributeName) = \"\(attributeName)\"");
            }
            print("}")
            
            print("")
            
            print("struct \(entity.name!)Relationship {")
            let sortedRelationshipKeys = entity.relationshipsByName.keys.sort {
                $0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending
            }
            for relationshipByName in sortedRelationshipKeys {
                print("\tstatic let \(relationshipByName) = \"\(relationshipByName)\"");
            }
            print("}")
            
            print("")
            
            //print("@objc(\(entity.name!.capitalizedString))")
        }
    }
    
}