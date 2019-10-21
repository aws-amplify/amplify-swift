//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// MARK: - PersistenValue

/// Types conforming to this protocol can be used as properties of models.
/// Examples include `String`, `Int`, `Decimal`, `Bool` and `Date`.
public protocol PersistentValue {}
extension String: PersistentValue {}
extension Int: PersistentValue {}
extension Decimal: PersistentValue {}
extension Date: PersistentValue {}
extension Bool: PersistentValue {}

// MARK: - PropertyAttribute

/// `PropertyAttribute` values are used to decorate model properties with extra information.
/// This is useful for storing extra information needed in order to execute persistence-related operations.
public enum PropertyAttribute {

    /// Property-level authorization rules.
    /// - See: `Authorizable`
    case auth(rules: AuthRules)

    ///
    case connection(name: String?)

    /// Marks a property as the Model primary key (i.e. the unique identifier).
    case primaryKey

    /// Marks a property as the one that controls the version of the model.
    /// - See: `Versionable`
    case versioned
}

// MARK: - PropertyMetadata

/// 
public indirect enum PropertyType {
    case string
    case int
    case decimal
    case date
    case boolean
    case `enum`(_ type: AnyClass)
    case model(_ type: PersistentModel.Type)
    case collection(_ propertyType: PropertyType)
}

/// Data structure that holds all the metadata related to a Model property.
public struct PropertyMetadata {

    ///
    public let key: CodingKey

    ///
    public let type: PropertyType

    ///
    public let optional: Bool

    ///
    public let attributes: [PropertyAttribute]

    init(key: CodingKey,
         type: PropertyType,
         optional: Bool = false,
         attributes: [PropertyAttribute] = []) {
        self.key = key
        self.type = type
        self.optional = optional
        self.attributes = attributes
    }

    /// The `name` of the property. It's just a shortcut to `key.stringValue`.
    public var name: String {
        key.stringValue
    }

    /// Resolves the
    ///
    /// - Returns: the connected model metatype if the property is connected
    /// (i.e. `type` is `.model` or `.collection`) or `nil` otherwise.
    public var connectedModel: PersistentModel.Type? {
        switch type {
        case let .model(modelType):
            return modelType
        case let .collection(.model(modelType)):
            return modelType
        default:
            return nil
        }
    }

    public var isConnected: Bool {
        return attributes.first { attr in
            switch attr {
            case .connection:
                return true
            default:
                return false
            }
        } != nil
    }

    public var isPrimaryKey: Bool {
        return attributes.first { attr in
            switch attr {
            case .primaryKey:
                return true
            default:
                return false
            }
        } != nil
    }
}

public protocol ModelProperty {
    var metadata: PropertyMetadata { get }

    func property(type: PropertyType,
                  optional: Bool,
                  attributes: PropertyAttribute...) -> PropertyMetadata
}

extension ModelProperty where Self: CodingKey {
    public func property(type: PropertyType,
                         optional: Bool = false,
                         attributes: PropertyAttribute...) -> PropertyMetadata {
        return PropertyMetadata(key: self, type: type, optional: optional, attributes: attributes)
    }
}
