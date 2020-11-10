//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Defines the association type between two models. The type of association is
/// important when defining how to store and query them. Each association have
/// its own rules depending on the storage mechanism.
///
/// The semantics of a association can be defined as:
///
/// **Many-to-One/One-to-Many**
///
/// The most common association type. It defines an array/collection on one side and a
/// single `Model` reference on the other. The side with the `Model` (marked as `belongsTo`)
/// holds a reference to the other side's `id` (aka "foreign key").
///
/// Example:
///
/// ```
/// struct Post: Model {
///   let id: Model.Identifier
///
///   // hasMany(associatedWith: Comment.keys.post)
///   let comments: [Comment]
/// }
///
/// struct Comment: Model {
///   let id: Model.Identifier
///
///   // belongsTo
///   let post: Post
/// }
/// ```
///
/// **One-to-One**
///
/// This type of association is not too common since in these scenarios data can usually
/// be normalized and stored under the same `Model`. However, there are use-cases where
/// one-to-one can be useful, specially when one side of the association is optional.
///
/// Example:
///
/// ```
/// struct Person: Model {
///   // hasOne(associatedWith: License.keys.person)
///   let license: License?
/// }
///
/// struct License: Model {
///   // belongsTo
///   let person: Person
/// }
/// ```
///
/// **Many-to-Many**
///
/// These associations mean that an instance of one `Model` can relate to many other
/// instances of another `Model` and vice-versa. Many-to-Many is achieved by combining
/// `hasMany` and `belongsTo` with an intermediate `Model` that is responsible for
/// holding a reference to the keys of both related models.
///
/// ```
/// struct Book: Model {
///   // hasMany(associatedWith: BookAuthor.keys.book)
///   let auhors: [BookAuthor]
/// }
///
/// struct Author: Model {
///   // hasMany(associatedWith: BookAuthor.keys.author)
///   let books: [BookAuthor]
/// }
///
/// struct BookAuthor: Model {
///   // belongsTo
///   let book: Book
///
///   // belongsTo
///   let author: Author
/// }
/// ```
///
/// - Warning: Although this has `public` access, it is intended for internal use and should not be used directly
///   by host applications. The behavior of this may change without warning.
public enum ModelAssociation {
    case hasMany(associatedWith: String?)
    case hasOne(associatedWith: String?)
    case belongsTo(associatedWith: String?, targetName: String?)

    public static let belongsTo: ModelAssociation = .belongsTo(associatedWith: nil, targetName: nil)

    public static func belongsTo(targetName: String? = nil) -> ModelAssociation {
        return .belongsTo(associatedWith: nil, targetName: nil)
    }

}

extension ModelField {

    /// - Warning: Although this has `public` access, it is intended for internal use and should not be used directly
    ///   by host applications. The behavior of this may change without warning.
    public var hasAssociation: Bool {
        return association != nil
    }

    /// If the field represents an association returns the `ModelName`.
    /// - seealso: `ModelFieldType`
    /// - seealso: `ModelFieldAssociation`
    /// - Warning: Although this has `public` access, it is intended for internal use and should not be used directly
    ///   by host applications. The behavior of this may change without warning.
    public var associatedModelName: ModelName? {
        switch type {
        case .model(let modelName), .collection(let modelName):
            return modelName
        default:
            return nil
        }
    }

    /// This calls `associatedModelName` but enforces that the field must represent an association.
    /// In case the field type is not a `Model` it calls `preconditionFailure`. Consumers
    /// should fix their models in order to recover from it, since associations are only
    /// possible between two `Model`.
    ///
    /// - Note: as a maintainer, make sure you use this computed property only when context
    /// allows (i.e. the field is a valid relationship, such as foreign keys).
    /// - Warning: Although this has `public` access, it is intended for internal use and should not be used directly
    ///   by host applications. The behavior of this may change without warning.
    public var requiredAssociatedModel: ModelName {
        guard let modelName = associatedModelName else {
            preconditionFailure("""
            Model fields that are foreign keys must be connected to another Model.
            Check the `ModelSchema` section of your "\(name)+Schema.swift" file.
            """)
        }
        return modelName
    }

    /// - Warning: Although this has `public` access, it is intended for internal use and should not be used directly
    ///   by host applications. The behavior of this may change without warning.
    public var isAssociationOwner: Bool {
        guard case .belongsTo = association else {
            return false
        }
        return true
    }

    /// - Warning: Although this has `public` access, it is intended for internal use and should not be used directly
    ///   by host applications. The behavior of this may change without warning.
    public var associatedField: ModelField? {
        if hasAssociation {
            let associatedModel = requiredAssociatedModel
            switch association {
            case .belongsTo(let associatedKey, _):
                // TODO handle modelName casing (convert to camelCase)
                let key = associatedKey ?? associatedModel
                let schema = ModelRegistry.modelSchema(from: associatedModel)
                return schema?.field(withName: key)
            case .hasOne(let associatedKey),
                 .hasMany(let associatedKey):
                // TODO handle modelName casing (convert to camelCase)
                let key = associatedKey ?? associatedModel
                let schema = ModelRegistry.modelSchema(from: associatedModel)
                return schema?.field(withName: key)
            case .none:
                return nil
            }
        }
        return nil
    }

    /// - Warning: Although this has `public` access, it is intended for internal use and should not be used directly
    ///   by host applications. The behavior of this may change without warning.
    public var isOneToOne: Bool {
        if case .hasOne = association {
            return true
        }
        if case .belongsTo = association, case .hasOne = associatedField?.association {
            return true
        }
        return false
    }

    /// - Warning: Although this has `public` access, it is intended for internal use and should not be used directly
    ///   by host applications. The behavior of this may change without warning.
    public var isOneToMany: Bool {
        if case .hasMany = association, case .belongsTo = associatedField?.association {
            return true
        }
        return false
    }

    /// - Warning: Although this has `public` access, it is intended for internal use and should not be used directly
    ///   by host applications. The behavior of this may change without warning.
    public var isManyToOne: Bool {
        if case .belongsTo = association, case .hasMany = associatedField?.association {
            return true
        }
        return false
    }

    /// - Warning: Although this has `public` access, it is intended for internal use and should not be used directly
    ///   by host applications. The behavior of this may change without warning.
    public var embeddedTypeSchema: ModelSchema? {
        switch type {
        case .embedded(_, let modelSchema), .embeddedCollection(_, let modelSchema):
            return modelSchema
        default:
            return nil
        }
    }

    /// - Warning: Although this has `public` access, it is intended for internal use and should not be used directly
    ///   by host applications. The behavior of this may change without warning.
    public var isEmbeddedType: Bool {
        switch type {
        case .embedded, .embeddedCollection:
            return true
        default:
            return false
        }
    }
}
