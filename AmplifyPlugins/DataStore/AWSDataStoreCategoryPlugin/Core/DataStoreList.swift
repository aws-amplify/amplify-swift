//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import Combine

/// `DataStoreList<ModelType>` is a DataStore-aware custom `Collection` that is capable of loading
/// records from the `DataStore` on-demand. This is specially useful when dealing with
/// Model associations that need to be lazy loaded.
///
/// When using `DataStore.query(_ modelType:)` some models might contain associations
/// with other models and those aren't fetched automatically. This collection keeps track
/// of the associated `id` and `field` and fetches the associated data on demand.
public class DataStoreList<ModelType: Model>: List<ModelType>, ModelListDecoder {

    /// If the list represents an association between two models, the `associatedId` will
    /// hold the information necessary to query the associated elements (e.g. comments of a post)
    var associatedId: Model.Identifier?

    /// The associatedField represents the field to which the owner of the `List` is linked to.
    /// For example, if `Post.comments` is associated with `Comment.post` the `List<Comment>`
    /// of `Post` will have a reference to the `post` field in `Comment`.
    var associatedField: ModelField?

    var storedElements: [Element]

    var limit: Int = 100

    /// The current state of lazily loaded list
    var state = LoadState.pending

    public override var elements: Elements {
        storedElements
    }

    // MARK: - Initializers

    init(_ elements: Elements) {
        self.storedElements = elements
        self.state = .loaded
    }

    init(associatedId: Model.Identifier? = nil,
         associatedField: ModelField? = nil) {
        self.storedElements = []
        self.associatedId = associatedId
        self.associatedField = associatedField
        super.init()
    }

    // MARK: - ExpressibleByArrayLiteral

    required convenience public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }

    // MARK: - Collection conformance

    /// This method implicitly lazy loads the underlying collection so the runtime of using Collection methods that
    /// are normally O(1) are decreased to the time it takes to retrieve the data from the underlying SQL data source
    /// for the initial method call. After the first access, the data will be retrieved and subsequent calls will be
    /// O(1) runtime.
    public override var startIndex: Index {
        loadIfNeeded()
        return elements.startIndex
    }

    public override var endIndex: Index {
        return elements.endIndex
    }

    public override func index(after index: Index) -> Index {
        return elements.index(after: index)
    }

    public override subscript(position: Int) -> Element {
        return elements[position]
    }

    /// This method implicitly lazy loads the underlying collection so the runtime of using Collection methods that
    /// are normally O(1) are decreased to the time it takes to retrieve the data from the underlying SQL data source
    /// for the initial method call. After the first access, the data will be retrieved and subsequent calls will be
    /// O(1) runtime.
    override public __consuming func makeIterator() -> IndexingIterator<Elements> {
        loadIfNeeded()
        return elements.makeIterator()
    }

    // MARK: - Persistent Operations

    @available(*, deprecated, message: "Not supported.")
    public override func limit(_ limit: Int) -> Self {
        // TODO handle query with limit
        self.limit = limit
        state = .pending
        return self
    }

    // MARK: - Codable

    required convenience init(from decoder: Decoder) throws {
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
                self.init(associatedId: associatedId, associatedField: field)
            } else {
                self.init(Elements())
            }
        default:
            self.init(Elements())
        }
    }

    // MARK: ModelListDecoder

    public static func shouldDecode(decoder: Decoder) -> Bool {
        guard let json = try? JSONValue(from: decoder) else {
            return false
        }
        return shouldDecode(json: json)
    }

    static func shouldDecode(json: JSONValue) -> Bool {
        if case let .object(list) = json,
           case .string = list["associatedId"],
           case .string = list["associatedField"] {
            return true
        }

        if case .array = json {
            return true
        }

        return false
    }

    public static func decode<ModelType: Model>(decoder: Decoder,
                                                modelType: ModelType.Type) throws -> List<ModelType> {
        try DataStoreList<ModelType>.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        try elements.encode(to: encoder)
    }

    // MARK: - Asynchronous API

    /// Trigger `DataStore` query to initialize the collection. This function always
    /// fetches data from the `DataStore.query`.
    ///
    /// - seealso: `load()`
    public override func load(_ completion: DataStoreCallback<Elements>) {
        lazyLoad(completion)
    }

    // MARK: - Synchronous API

    /// Trigger `DataStore` query to initialize the collection. This function always
    /// fetches data from the `DataStore.query`. However, consumers must be aware of
    /// the internal behavior which relies on `DispatchSemaphore` and will block the
    /// current `DispatchQueue` until data is ready. When operating on large result
    /// sets, prefer using the asynchronous `load(completion:)` instead.
    ///
    /// - Returns: the current instance after data was loaded.
    /// - seealso: `load(completion:)`
    public override func load() -> Self {
        lazyLoad()
        return self
    }

    // MARK: Combine

    /// Lazy load the collection and expose the loaded `Elements` as a Combine `Publisher`. The collection will
    /// immediately retrieve the data from when the publisher is returned. You can call `sink` to get the reuslts of
    /// the load in O(1). This is useful for integrating the `List<ModelType>` with existing Combine code
    /// and/or SwiftUI.
    ///
    /// - Returns: a type-erased Combine publisher
    @available(iOS 13.0, *)
    @available(*, deprecated, message: "Use `load` instead.")
    public override func loadAsPublisher() -> LazyListPublisher {
        return Future { promise in
            self.load {
                switch $0 {
                case .success(let elements):
                    promise(.success(elements))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
}
