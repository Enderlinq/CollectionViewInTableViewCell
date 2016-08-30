//
//  NSManagedObject+Parsing.swift
//  CoreData2
//
//  Created by mrandall on 10/12/15.
//  Copyright © 2015 mrandall. All rights reserved.
//

import Foundation
import CoreData

//MARK: - Parsing Errors

public enum UpdateWithJSONError: ErrorType {
    case AttributeMappingIsNotSupported
    case RelationshipMappingIsNotSupported
    case PropertyNotFoundOnObject(mappingKey: String)
    case JSONKeyPathValueIsUnexpectedObjectType(attributedName: String)
    case JSONValueIsUnexpectedObjectType(attributedName: String)
    case AttributeValueTransformFailed(attributedName: String)
    case RelationshipValueTransformFailed(relationshipName: String)
    case RelationShipDoesNotExist(relationshipName: String)
}

//MARK: - Parsing

public extension NSManagedObject {
    
    /// Updated Self with JSON using property to JSON Key / JSON parser
    ///
    /// - Parameter: JSON [String: AnyObject] JSON Dictionary
    /// - propertyToJSONMapping: [String: AnyObject]?
    ///     key is name of property of Self
    ///     if value is a 'String' its value maps to a key in the JSON.
    ///     If the key is in the JSON, this value is set for the property if the property is an attribute
    ///     if vaue is a 'JSONParsingValueTransformer' it is used to transform value in the JSON if it is found.
    ///
    public func updateWithJSON(
        JSON: [String: AnyObject],
        propertyToJSONMapping: [String: AnyObject]? = nil
        ) throws {
        
        //if mapping is nil use self array keys as default mappings
        let mapping: [String: AnyObject]
        if let propertyToJSONMapping = propertyToJSONMapping {
            mapping = propertyToJSONMapping
        } else {
            mapping = Array(JSON.keys).reduce([String: AnyObject]()) { (var d, k) in
                d[k] = k
                return d
            }
        }
        
        //check if all keys in mapping are properties of Self
        for (key, _) in mapping {
            
            //check if attribute exists of Self
            if self.entity.propertiesByName[key] == nil {
                throw UpdateWithJSONError.PropertyNotFoundOnObject(mappingKey: key)
            }
        }
        
        //parse properties in mapping
        //keys are the names of NSMananagedObject attributes
        for property in Array(mapping.keys) {
            
            //raw JSONParsingCompositeValueTransformer
            if let compositeTransformer = mapping[property] as? JSONParsingCompositeValueTransformer {
                try compositeTransformer.updateEntity(self, property: property, withJSON: JSON)
            }
            
            //check if property is an attibute
            else if let attributeDescription = self.entity.attributesByName[property] {
                
                do {
                    
                    //get attributed value
                    let attributeValue: AnyObject?
                    
                    //get attributed value from transformer
                    if let valueTransformer = mapping[property] as? JSONParsingValueTransformer {
                        
                        //get value for keyPath cached by transformer
                        guard let attributeValueNotTransformed = try JSON.valueFor(keyPath: valueTransformer.JSONKey) else { continue }
                        
                        //transform value from JSON
                        //If transform returns a nil value transform does not fail. Core Data validation is responsible for options
                        //Transform may throw a more specific error
                        attributeValue = try valueTransformer.transform(value: attributeValueNotTransformed)
                        
                        //check if null
                        //if null set as nil and continue, Core Data validation will handle non optional attributes being nil
                        guard attributeValue as? NSNull == nil else {
                            self.setValue(nil, forKey: property)
                            continue
                        }
                        
                        //get attribute value from simple mapping
                        //simple mapping is where no mapping is defined
                        //and the JSON attribute name matches the NSManagedObject Attribute name associated with it
                    } else if let JSONKey = mapping[property] as? String {
                        
                        //get value in JSON for keyPath
                        attributeValue = try JSON.valueFor(keyPath: JSONKey)
                        
                        //check if null
                        //if null set as nil and continue, Core Data validation will handle non optional attributes being nil
                        guard attributeValue as? NSNull == nil else {
                            setValue(nil, forKey: property)
                            continue
                        }
                        
                        //mapping not found for property
                    } else {
                        throw UpdateWithJSONError.AttributeMappingIsNotSupported
                    }
                    
                    //check if null
                    //NSNull() is not nil here.
                    // ... NSNull means the value is in the JSON but null. The property value is set to nil / null
                    // ... nil means the JSON key is not in the JSON. The property value is not updated
                    
                    //If attributeValue is nil (nont NSNull) the attribute according to its mapping is not in the JSON
                    //Leave the attribute value asis and continue
                    guard let attributeValueUnwrapped = attributeValue else {
                        continue
                    }
                    
                    //check if JSON value matches attribute.attributeType
                    guard self.isAttributeValue(attributeValueUnwrapped, validForType: attributeDescription.attributeType) else {
                        throw UpdateWithJSONError.JSONValueIsUnexpectedObjectType(attributedName: property)
                    }
                    
                    //set attribute value
                    setValue(attributeValueUnwrapped, forKey: property)
                    
                } catch UpdateWithJSONTransformerError.TransformJSONKeyNotFoundInJSON {
                    continue;
                    
                    //If JSON value transform failed
                } catch UpdateWithJSONTransformerError.TransformFailed {
                    throw UpdateWithJSONError.AttributeValueTransformFailed(attributedName: property)
                    
                    //If JSON value transform failed
                } catch {
                    throw error
                }
            }
            
            //check if property is a relationship
            else if let entityDescription = self.entity.relationshipsByName[property] {
                
                //check for value mapping
                guard let relationshipTransformer = mapping[property] as? JSONParsingRelationshipTransformer else {
                    throw UpdateWithJSONError.AttributeMappingIsNotSupported
                }
                
                do {
                    
                    //get value for keyPath cached by transformer
                    guard let JSONAtKeyPath = try JSON.valueFor(keyPath: relationshipTransformer.JSONKey) else { continue }
                    
                    //toMany transformer
                    if let toManyTransformer = relationshipTransformer as? JSONParsingToManyRelationshipTransformer {
                        
                        //array of JSON objects
                        if let JSONArray = JSONAtKeyPath as? [[String: AnyObject]] {
                            try toManyTransformer.updateEntity(self, relationship: property, withJSON: JSONArray)
                            
                            //array of values
                        } else if let JSONArray = JSONAtKeyPath as? [AnyObject] {
                            try toManyTransformer.updateEntity(self, relationship: property, withJSON: JSONArray)
                            
                            //value is null
                            //null value will set value to empty set or orderedset
                        } else if let nullValue = JSONAtKeyPath as? NSNull {
                            
                            if entityDescription.ordered == true {
                                setValue(NSOrderedSet(), forKey: property)
                            } else {
                                setValue(NSSet(), forKey: property)
                            }
                            
                            continue
                            
                        } else {
                            throw UpdateWithJSONError.JSONKeyPathValueIsUnexpectedObjectType(attributedName: property)
                        }
                        
                        //toOne transformer
                    } else if let toOneTransformer = relationshipTransformer as? JSONParsingToOneRelationshipTransformer {
                        
                        //array of JSON objects
                        if let JSONDictionary = JSONAtKeyPath as? [String: AnyObject] {
                            try toOneTransformer.updateEntity(self, relationship: property, withJSON: JSONDictionary)
                            
                            //check if null
                            //if null set as nil and continue, Core Data validation will handle non optional attributes being nil
                        } else if let nullValue = JSONAtKeyPath as? NSNull {
                            setValue(nil, forKey: property)
                            continue
                            
                        } else {
                            throw UpdateWithJSONError.JSONKeyPathValueIsUnexpectedObjectType(attributedName: property)
                        }
                        
                        //transformer not supported
                    } else {
                        throw UpdateWithJSONError.RelationshipMappingIsNotSupported
                    }
                    
                    //If JSON doens't contain the key specified by the transformer move on
                    //Transformer threw an error because value for key was not in JSON
                } catch UpdateWithJSONTransformerError.TransformJSONKeyNotFoundInJSON {
                    continue;
                    
                    //If JSON value transform failed
                    //Transformer threw an error
                } catch UpdateWithJSONTransformerError.TransformFailed {
                    throw UpdateWithJSONError.RelationshipValueTransformFailed(relationshipName: property)
                    
                    //If JSON value transform failed
                } catch {
                    throw error
                }
            }
        }
    }
    
    /// Update entity with JSON
    /// throws
    ///
    /// - parameter JSON [[String: AnyObject]]
    /// - parameter entityMapping JSONParsingMapping
    /// - parameter deleteEntitiesNotInJSON: BOOL
    /// - parameter deleteIfInvalid: Bool
    /// - parameter uniquingAttribute: String?
    /// - parameter updateEntityOutsideJSON: ((model: NSManagedObject) -> Void)?
    /// - parameter updateEntityOnlyIf: ((model: NSManagedObject, modelJSON: [String: AnyObject]) -> Bool)?
    /// - parameter moc: NSManagedObjectContext
    public class func updateAllWithJSON(
        JSON: [[String: AnyObject]],
        entityMapping: [String: AnyObject]? = nil,
        deleteEntitiesNotInJSON: Bool = true,
        deleteIfInvalid: Bool = true,
        uniquingAttribute: String? = nil,
        updateEntityOutsideJSON: ((model: NSManagedObject) -> Void)? = nil,
        updateEntityOnlyIf: ((model: NSManagedObject, modelJSON: [String: AnyObject]) -> Bool)? = nil,
        moc: NSManagedObjectContext
        ) throws {
        
        //get Class of self
        
        //cache relationship entities in context/relationship
        let entitiesInContext = Set<NSManagedObject>(self.fetchAll(sortOn: nil, moc: moc))
        
        //cache all existing
        var cachedEntitiesByUniquingAttribute: [String: NSManagedObject]?
        if let uniquingAttribute = uniquingAttribute {
            cachedEntitiesByUniquingAttribute = cachedByUniquingAttribute(
                entities: entitiesInContext,
                uniquingAttribute: uniquingAttribute
            )
        }
        
        //cache relationship entities in JSON
        var entitiesInJSON = Set<NSManagedObject>()
        
        for entityJSON in JSON {
            
            //fetch from cache else create entity
            if
                cachedEntitiesByUniquingAttribute != nil,
                let uniquingAttribute = uniquingAttribute,
                let mapping = entityMapping,
                let uniquingAttributeValueInJSONKey = mapping[uniquingAttribute] as? String,
                let uniquingAttributeValueInJSON = try entityJSON.valueFor(keyPath: uniquingAttributeValueInJSONKey) as? String,
                let cached = cachedEntitiesByUniquingAttribute![uniquingAttributeValueInJSON]
            {
                
                //check if entity should be updated
                let update: Bool
                if let updateEntityOnlyIf = updateEntityOnlyIf {
                    update = updateEntityOnlyIf(model: cached, modelJSON: entityJSON)
                } else {
                    update = true
                }
                
                if update == true {
                    
                    //update entity with JSON
                    try cached.updateWithJSON(entityJSON, propertyToJSONMapping: entityMapping)
                    
                    //update entity outside JSON
                    if let outsideJSON = updateEntityOutsideJSON {
                        outsideJSON(model: cached)
                    }
                }
                
                //add to inJSON set
                entitiesInJSON.insert(cached)
                
            } else {
                let entity = self.createInContext(moc)
                
                //update entity with JSON
                try entity.updateWithJSON(entityJSON, propertyToJSONMapping: entityMapping)
                
                //update entity outside JSON
                if let outsideJSON = updateEntityOutsideJSON {
                    outsideJSON(model: entity)
                }
                
                //add to inJSON set
                entitiesInJSON.insert(entity)
                
                //cache newly created if uniquingAttribute and cache are being used
                if
                    let uniquingAttribute = uniquingAttribute,
                    var cache = cachedEntitiesByUniquingAttribute,
                    let cacheKey = entity.valueForKey(uniquingAttribute) as? String
                    
                {
                    cache[cacheKey] = entity
                }
            }
        }
        
        if deleteEntitiesNotInJSON == true {
            //delete entitiesInContext - entitiesInJSON
            entitiesInContext.subtract(entitiesInJSON).forEach {
                moc.deleteObject($0)
            }
        }
        
        if deleteIfInvalid == true {
            //valid entities in relationship
            entitiesInJSON.forEach {
                do {
                    try $0.validateForInsert()
                    try $0.validateForUpdate()
                    //If validation failes delete
                } catch {
                    moc.deleteObject($0)
                }
            }
        }
    }
    
    /// Update entity relationship with JSON
    /// throws
    ///
    /// - parameter relationshipName String
    /// - parameter relationshipClass NSManagedObject.Type
    /// - parameter JSON [[String: AnyObject]]
    /// - parameter relationshipEntityMapping JSONParsingMapping
    /// - parameter deleteEntitiesNotInJSON: BOOL
    /// - parameter deleteIfInvalid: BOOL
    /// - parameter uniquingAttribute: String?
    /// - parameter updateEntityOutsideJSON: ((model: NSManagedObject) -> Void)?
    /// - parameter updateEntityOnlyIf: ((model: NSManagedObject, modelJSON: [String: AnyObject]) -> Bool)?
    public func updateToManyRelationship(
        relationshipName: String,
        relationshipClass: NSManagedObject.Type,
        JSON: [[String: AnyObject]],
        relationshipEntityMapping: [String: AnyObject]? = nil,
        deleteEntitiesNotInJSON: Bool = true,
        deleteIfInvalid: Bool = true,
        uniquingAttribute: String? = nil,
        updateEntityOutsideJSON: ((model: NSManagedObject) -> Void)? = nil,
        updateEntityOnlyIf: ((model: NSManagedObject, modelJSON: [String: AnyObject]) -> Bool)? = nil
        ) throws {
        
        //cache relationship entities in context/relationship
        let inContext: Set<NSManagedObject>?
        let ordered: Bool
        
        //check if not ordered relationship / attempt to cast to Set
        if let notOrderedInContext = self.valueForKey(relationshipName) as? Set<NSManagedObject> {
            inContext = notOrderedInContext
            ordered = false
            //check if not ordered relationship / attempt to cast to NSOrderedSet
            //then cast .array to Swift array
        } else if
            let orderedInContextAsOrderedSet = self.valueForKey(relationshipName) as? NSOrderedSet,
            let orderedInContextAsArray = orderedInContextAsOrderedSet.array as? [NSManagedObject]
        {
            inContext = Set<NSManagedObject>(orderedInContextAsArray)
            ordered = true
        } else {
            inContext = nil
            ordered = false
        }
        
        //if relationship doesn't exist by KVO assuming it doesn't exist and throw
        guard let relationshipEntitiesInContext = inContext else {
            throw UpdateWithJSONError.RelationShipDoesNotExist(relationshipName: relationshipName)
        }
        
        //cache all existing
        var cachedEntitiesByUniquingAttribute: [String: NSManagedObject]?
        if let uniquingAttribute = uniquingAttribute {
            cachedEntitiesByUniquingAttribute = cachedByUniquingAttribute(
                entities: relationshipEntitiesInContext,
                uniquingAttribute: uniquingAttribute
            )
        }
        
        //cache relationship entities in JSON
        //using array to support ordered relationships
        var relationshipEntitiesInJSON = [NSManagedObject]()
        
        for relationshipEntityJSON in JSON {
            
            //fetch from cache else create entity
            if
                cachedEntitiesByUniquingAttribute != nil,
                let uniquingAttribute = uniquingAttribute,
                let mapping = relationshipEntityMapping,
                let uniquingAttributeValueInJSONKey = mapping[uniquingAttribute] as? String,
                let uniquingAttributeValueInJSON = try relationshipEntityJSON.valueFor(keyPath: uniquingAttributeValueInJSONKey) as? String,
                let cached = cachedEntitiesByUniquingAttribute![uniquingAttributeValueInJSON]
            {
                //check if entity should be updated
                let update: Bool
                if let updateEntityOnlyIf = updateEntityOnlyIf {
                    update = updateEntityOnlyIf(model: cached, modelJSON: relationshipEntityJSON)
                } else {
                    update = true
                }
                
                if update == true {
                    
                    //update entity with JSON
                    try cached.updateWithJSON(relationshipEntityJSON, propertyToJSONMapping: relationshipEntityMapping)
                    
                    //update entity outside JSON
                    if let outsideJSON = updateEntityOutsideJSON {
                        outsideJSON(model: cached)
                    }
                }
                
                //cache for in JSON
                relationshipEntitiesInJSON.append(cached)
                
            } else {
                
                //create
                let relationshipEntity = relationshipClass.createInContext(self.managedObjectContext!)
                
                //update entity with JSON
                try relationshipEntity.updateWithJSON(relationshipEntityJSON, propertyToJSONMapping: relationshipEntityMapping)
                
                //update entity outside JSON
                if let outsideJSON = updateEntityOutsideJSON {
                    outsideJSON(model: relationshipEntity)
                }
                
                //cache for in JSON
                relationshipEntitiesInJSON.append(relationshipEntity)
                
                //cache for general
                //newly created if uniquingAttribute and cache are being used
                if
                    let uniquingAttribute = uniquingAttribute,
                    var cache = cachedEntitiesByUniquingAttribute,
                    let cacheKey = relationshipEntity.valueForKey(uniquingAttribute) as? String
                    
                {
                    cache[cacheKey] = relationshipEntity
                }
            }
        }
    
        
        //update relationship
        //do before validation in case relationship is required
        
        //if deleteEntitiesNotInJSON is true set relationship to relationshipEntitiesInJSON data
        //then delete relationshipEntitiesInContext minus relationshipEntitiesInJSON
        if deleteEntitiesNotInJSON == true {
            
            if ordered == true {
                let orderedSet = NSOrderedSet(array: relationshipEntitiesInJSON)
                setValue(orderedSet, forKey: relationshipName)
            } else {
                let set = Set<NSManagedObject>(relationshipEntitiesInJSON)
                setValue(set, forKey: relationshipName)
            }
            
            //delete relationshipEntitiesInContext - relationshipEntitiesInJSON
            relationshipEntitiesInContext.subtract(relationshipEntitiesInJSON).forEach {
                self.managedObjectContext!.deleteObject($0)
            }
            
            
        } else {
            
            //check ordered flag cast to appropriate data type for relationship
            
            //If ordered add relationshipEntitiesInJSON to existing set
            if ordered == true {
                
                let orderedInContextAsOrderedSet = (self.valueForKey(relationshipName) as! NSOrderedSet).mutableCopy()
                
                relationshipEntitiesInJSON.forEach {
                    orderedInContextAsOrderedSet.addObject($0)
                }
                
                //let orderedSet = NSOrderedSet(array: relationshipEntitiesInJSON)
                setValue(orderedInContextAsOrderedSet, forKey: relationshipName)
                
            //If not order set to the union of relationshipEntitiesInContext and relationshipEntitiesInJSON
            } else {
                let allEntries = relationshipEntitiesInContext.union(Set<NSManagedObject>(relationshipEntitiesInJSON))
                setValue(allEntries, forKey: relationshipName)
            }
        }
        
        if deleteIfInvalid == true {
            //valid entities in relationship
            relationshipEntitiesInJSON.forEach {
                do {
                    try $0.validateForInsert()
                    try $0.validateForUpdate()
                    
                    //If validation fails delete
                } catch {
                    self.managedObjectContext!.deleteObject($0)
                }
            }
        }
    }
    
    /// Check if  value is valid for attribute
    ///
    /// parameter: value: AnyObject
    /// parameter: validForType: NSAttributeType
    /// return: Bool
    public func isAttributeValue(
        value: AnyObject,
        validForType
        type: NSAttributeType
        ) -> Bool {
        
        switch type {
            
        case .Integer16AttributeType, .Integer32AttributeType, .Integer64AttributeType, .DecimalAttributeType, .DoubleAttributeType, .FloatAttributeType:
            guard let _ = value as? Float else { return false }
            
        case .StringAttributeType:
            guard let _ = value as? String else { return false }
            
        case .DateAttributeType:
            guard let _ = value as? NSDate else { return false }
            
        case .BooleanAttributeType:
            guard let _ = value as? Bool else { return false }
            
        case .BinaryDataAttributeType:
            guard let _ = value as? NSData else { return false }
            
        case .UndefinedAttributeType, .ObjectIDAttributeType:
            return false
            
        case .TransformableAttributeType:
            return true
            
        }
        
        return true
    }
}

//MARK: - Util

// Creates and returns dictionary in the form [UniquingAttribute value for Entity: Entity]
//
// - Parameter enitities: Set<NSManagedObject>
// - Parameter uniquingAttribute: String
// - Returns [String: NSManagedObject]
private func cachedByUniquingAttribute(
    entities entities: Set<NSManagedObject>,
             uniquingAttribute: String
    ) -> [String: NSManagedObject] {
    
    return entities.reduce([String:NSManagedObject]()) {
        (reduced: [String: NSManagedObject], entity: NSManagedObject) -> [String: NSManagedObject] in
        var reduced = reduced
        if let value = entity.valueForKey(uniquingAttribute) as? String {
            reduced[value] = entity
        }
        return reduced
    }
}

private extension Dictionary where Key: StringLiteralConvertible, Value: AnyObject {
    
    // JSON value at keyPath. Swift KVC replacement for [String: AnyObject]
    // - TODO: investigate cleaning this up
    //
    // - Parameter keyPath: String
    // - Return AnyObject?
    // - Throws UpdateWithJSONError.JSONKeyPathValueIsUnexpectedObjectType with empty associated value
    func valueFor(keyPath keyPath: String) -> AnyObject? {
        
        //cast to [String: AnyObject]
        guard let castSelf = (self as? AnyObject) as? Dictionary<String, AnyObject> else {
            return nil
        }
        
        //split on '.'
        var JSONKeyPathKeys = keyPath.componentsSeparatedByString(".")
        
        //cache last key
        let lastKey = JSONKeyPathKeys.popLast()!
        
        //get JSON for second to last key
        let JSON = try JSONKeyPathKeys.reduce(castSelf) { (JSON, key) in
            
            var JSON = JSON
            
            //return an empty JSON object if keypath is not found
            //this ensures that this method returns nil
            guard let nextJSON = JSON[key] as? [String: AnyObject] else {
                return [:]
            }
            
            return nextJSON
        }
        
        return JSON[lastKey]
    }
}