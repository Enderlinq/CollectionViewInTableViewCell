//
//  Transformers.swift
//  Pods
//
//  Created by mrandall on 2/12/16.
//
//

import Foundation
import CoreData

//MARK: - JSON Parsing for composite values

//user this transform if you need all JSON be send into transformer for an entity to set a single property
public protocol JSONParsingCompositeValueTransformer {
    
    /// updateEntity
    ///
    /// - Parameter entity: NSManageObject entity to update with JSON
    /// - Parameter propert: String
    /// - Parameter withJSON: [String: AnyObject] to update entity with
    func updateEntity(entity: NSManagedObject, property: String, withJSON: [String: AnyObject]) throws
}

//MARK: Parsing Value Transformer

public enum UpdateWithJSONTransformerError: ErrorType {
    case TransformJSONKeyNotFoundInJSON
    case TransformFailed
}

public protocol JSONParsingValueTransformer {
    
    /// JSON key for value being transformed
    var JSONKey: String { get }
    
    /// return value from JSON['self.JSONKey'] transformed for attribute
    ///
    /// NOTE: return NSNull() is value should be null. returning nil will cause the attribute to be not be updated
    /// NSNull() is not nil here.
    /// ... NSNull means the value is in the JSON but null. The property value is set to nil / null
    /// ... nil means the JSON key is not in the JSON. The property value is not updated
    ///
    /// throws UpdateWithJSONTransformerError
    ///
    /// - Parameter value: AnyObject
    /// - Returns AnyObject?
    func transform(value value: AnyObject) throws -> AnyObject?
}

//MARK: - JSON Parsing Relationships

public protocol JSONParsingRelationshipTransformer {
    
    /// Key for [[String: AnyObject]] in the JSON to create relationship entities with
    var JSONKey: String { get }
    
    /// Class for NSManagedObject in the relationships many
    var relationshipClass: NSManagedObject.Type { get }
    
    /// Mapping for relationship entities
    var relationshipEntityMapping: [String: AnyObject]? { get }
    
    /// Whether entities current in the relationship which are not in the JSON should be deleted
    var deleteEntitiesNotInJSON: Bool { get }
    
    /// Delete NSManagedObjects created by transformer if not valide for insert or update
    var deleteIfInvalid: Bool { get }
}

public protocol JSONParsingToManyRelationshipTransformer: JSONParsingRelationshipTransformer {
    
    /// updateEntity
    ///
    /// - Parameter entity: NSManageObject entity to update relationship of
    /// - Parameter relationship: String
    /// - Parameter withJSON: [[String: AnyObject]] to update relationship with
    func updateEntity(entity: NSManagedObject, relationship: String, withJSON: [[String: AnyObject]]) throws
    
    /// updateEntity
    ///
    /// - Parameter entity: NSManageObject entity to update relationship of
    /// - Parameter relationship: String
    /// - Parameter withJSON: [[String: AnyObject]] to update relationship with
    func updateEntity(entity: NSManagedObject, relationship: String, withJSON: [AnyObject]) throws
}

extension JSONParsingToManyRelationshipTransformer {
    
    public func updateEntity(entity: NSManagedObject, relationship: String, withJSON: [AnyObject]) throws {
        let JSONNormalized = withJSON.filter { $0 is NSNull == false }
        guard let JSON = JSONNormalized as? [[String: AnyObject]] else { throw UpdateWithJSONTransformerError.TransformFailed }
        try updateEntity(entity, relationship: relationship, withJSON: JSON)
    }
    
    public func updateEntity(entity: NSManagedObject, relationship: String, withJSON: [[String: AnyObject]]) throws {
        try updateEntity(entity, relationship: relationship, withJSON: withJSON)
    }
}

public protocol JSONParsingToOneRelationshipTransformer: JSONParsingRelationshipTransformer {
    
    /// updateEntity
    ///
    /// - Parameter entity: NSManageObject entity to update relationship of
    /// - Parameter relationship: String
    /// - Parameter withJSON: [String: AnyObject] to update relationship with
    func updateEntity(entity: NSManagedObject, relationship: String, withJSON: [String: AnyObject]) throws
}

//MARK: - JSON Parsing Relationships - To Many

public class JSONParsingToMany: JSONParsingToManyRelationshipTransformer {
    
    public var JSONKey: String
    public var relationshipClass: NSManagedObject.Type
    public var relationshipEntityMapping: [String: AnyObject]?
    public var deleteEntitiesNotInJSON: Bool
    public var deleteIfInvalid: Bool
    
    public var updateEntityOutsideJSON: ((model: NSManagedObject) -> Void)?
    public var updateEntityOnlyIf: ((model: NSManagedObject, modelJSON: [String: AnyObject]) -> Bool)?
    public var uniquingAttribute: String?
    
    /// init
    ///
    /// - Parameter JSONKey: String
    /// - Parameter relationshipClass: NSManagedObject.Type
    /// - Parameter relationshipEntityMapping: [String: AnyObject]?
    /// - Parameter deleteEntitiesNotInJSON: Bool
    /// - Parameter deleteIfInvalid: Bool
    /// - Parameter uniquingAttribute: String?
    /// - parameter updateEntityOutsideJSON: ((model: NSManagedObject) -> Void)?
    /// - parameter updateEntityOnlyIf: ((model: NSManagedObject, modelJSON: [String: AnyObject]) -> Bool)?
    public init(JSONKey: String,
                relationshipClass: NSManagedObject.Type,
                relationshipEntityMapping: [String: AnyObject]? = nil,
                deleteEntitiesNotInJSON: Bool = true,
                deleteIfInvalid: Bool = true,
                uniquingAttribute: String? = nil,
                updateEntityOutsideJSON: ((model: NSManagedObject) -> Void)? = nil,
                updateEntityOnlyIf: ((model: NSManagedObject, modelJSON: [String: AnyObject]) -> Bool)? = nil
        ) {
        self.JSONKey = JSONKey
        self.relationshipClass = relationshipClass
        self.relationshipEntityMapping = relationshipEntityMapping
        self.deleteEntitiesNotInJSON = deleteEntitiesNotInJSON
        self.deleteIfInvalid = deleteIfInvalid
        self.uniquingAttribute = uniquingAttribute
        self.updateEntityOutsideJSON = updateEntityOutsideJSON
        self.updateEntityOnlyIf = updateEntityOnlyIf
    }
    
    public func updateEntity(
        entity: NSManagedObject,
        relationship: String,
        withJSON: [[String: AnyObject]]
        ) throws {
        
        try entity.updateToManyRelationship(relationship,
                                            relationshipClass: relationshipClass,
                                            JSON: withJSON,
                                            relationshipEntityMapping: relationshipEntityMapping,
                                            deleteEntitiesNotInJSON: deleteEntitiesNotInJSON,
                                            deleteIfInvalid:  deleteIfInvalid,
                                            uniquingAttribute: uniquingAttribute,
                                            updateEntityOutsideJSON: updateEntityOutsideJSON,
                                            updateEntityOnlyIf: updateEntityOnlyIf
        )
    }
}