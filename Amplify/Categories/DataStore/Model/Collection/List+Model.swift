//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `List<ModelType>` is a DataStore-aware custom `Collection` that is capable of loading
/// records from the `DataStore` on-demand. This is specially useful when dealing with
/// Model associations that need to be lazy loaded.
///
/// When using `DataStore.query(_ modelType:)` some models might contain associations
/// with other models and those aren't fetched automatically. This collection keeps track
/// of the associated `id` and `field` and fetches the associated data on demand.
public class List<ModelType: Model>: Collection, Codable, ExpressibleByArrayLiteral {

    public typealias Index = Int
    public typealias Element = ModelType
    public typealias Elements = [Element]

    public typealias ArrayLiteralElement = ModelType

    /// The array of `Element` that backs the custom collection implementation.
    internal var elements: Elements

    /// If the list represents an association between two models, the `associatedId` will
    /// hold the information necessary to query the associated elements (e.g. comments of a post)
    internal var associatedId: Model.Identifier?

    /// The associatedField represents the field to which the owner of the `List` is linked to.
    /// For example, if `Post.comments` is associated with `Comment.post` the `List<Comment>`
    /// of `Post` will have a reference to the `post` field in `Comment`.
    internal var associatedField: ModelField?

    internal var limit: Int = 100

    /// The current state of lazily loaded list
    internal var state: LoadState = .pending

    // MARK: - Initializers

    public convenience init(_ elements: Elements) {
        self.init(elements, associatedId: nil, associatedField: nil)
        self.state = .loaded
    }

    init(_ elements: Elements,
         associatedId: Model.Identifier? = nil,
         associatedField: ModelField? = nil) {
        self.elements = elements
        self.associatedId = associatedId
        self.associatedField = associatedField
    }

    // MARK: - ExpressibleByArrayLiteral

    required convenience public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }

    // MARK: - Collection conformance

    public var startIndex: Index {
        loadIfNeeded()
        return elements.startIndex
    }

    public var endIndex: Index {
        return elements.endIndex
    }

    public func index(after index: Index) -> Index {
        return elements.index(after: index)
    }

    public subscript(position: Int) -> Element {
        return elements[position]
    }

    public __consuming func makeIterator() -> IndexingIterator<Elements> {
        loadIfNeeded()
        return elements.makeIterator()
    }

    // MARK: - Persistent Operations

    public var totalCount: Int {
        // TODO handle total count
        return 0
    }

    public func limit(_ limit: Int) -> Self {
        // TODO handle query with limit
        self.limit = limit
        state = .pending
        return self
    }

    // MARK: - Codable

    required convenience public init(from decoder: Decoder) throws {
        let json = try JSONValue(from: decoder)
        switch json {
        case .array:
            let elements = try Elements(from: decoder)
            self.init(elements)
        case .object(let list):
            if case let .string(associatedId) = list["associatedId"],
               case let .string(associatedField) = list["associatedField"] {
                let field = Element.schema.field(withName: associatedField)
                // TODO handle eager loaded associations with elements
                self.init([], associatedId: associatedId, associatedField: field)
            } else if case let .array(jsonArray) = list["items"] {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
                let elements = try jsonArray.map { (jsonElement) -> Element in
                    let serializedJSON = try encoder.encode(jsonElement)
                    return try decoder.decode(Element.self, from: serializedJSON)
                }

                self.init(elements)
            } else {
                self.init(Elements())
            }
        default:
            self.init(Elements())
        }
    }

    public func encode(to encoder: Encoder) throws {
        try elements.encode(to: encoder)
    }

}
