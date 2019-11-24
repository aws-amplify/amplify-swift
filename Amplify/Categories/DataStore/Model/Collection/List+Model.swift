//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `List<ModelType>` is a DataStore-aware custom `Collection` that is capable of loading
/// records from the `DataStore` on-demand. This is specially useful when dealing with
/// Model associations that need to be lazy loaded.
///
/// When using `Data`
public class List<ModelType: Model>: Collection, Codable, ExpressibleByArrayLiteral {

    public typealias Index = Int
    public typealias Element = ModelType
    public typealias Elements = [Element]

    public typealias ArrayLiteralElement = ModelType

    /// The array of `Element` that backs the custom collection implementation
    internal var elements: Elements

    /// If the list represents a
    internal var associatedId: Model.Identifier?
    internal var associatedField: ModelField?

    internal var limit: Int = 100

    // The current state of the lazy load
    internal var state: LoadState = .pending

    // MARK: - Initializers

    public convenience init(_ elements: Elements) {
        self.init(elements, associatedId: nil, associatedField: nil)
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
