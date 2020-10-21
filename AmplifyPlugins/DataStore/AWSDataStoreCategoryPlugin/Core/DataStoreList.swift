//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import Combine

/// `DataStoreList<ModelType>` is a custom `Collection` that is capable of loading
/// records from the `DataStore` on-demand. This is specially useful when dealing with
/// Model associations that need to be lazy loaded.
///
/// When using `DataStore.query(_ modelType:)` some models might contain associations
/// with other models and those aren't fetched automatically. This collection keeps track
/// of the associated `id` and `field` and fetches the associated data on demand.
public class DataStoreList<ModelType: Model>: List<ModelType>, ModelListDecoder {

    /// If the list represents an association between two models, the `associatedId` will
    /// hold the information necessary to query the associated elements (e.g. comments of a post)
    internal var associatedId: Model.Identifier?

    /// The associatedField represents the field to which the owner of the `List` is linked to.
    /// For example, if `Post.comments` is associated with `Comment.post` the `List<Comment>`
    /// of `Post` will have a reference to the `post` field in `Comment`.
    internal var associatedField: ModelField?

    /// The current state of lazily loaded list
    internal var state: LoadState = .pending

    internal var limit: Int = 100

    // MARK: - Initializers

    public convenience override init(_ elements: Elements) {
        self.init(elements, associatedId: nil, associatedField: nil)
        self.state = .loaded
    }

    public init(_ elements: Elements,
                associatedId: Model.Identifier? = nil,
                associatedField: ModelField? = nil) {
        super.init(elements)
        self.associatedId = associatedId
        self.associatedField = associatedField
    }

    // MARK: - Collection conformance

    public override var startIndex: Index {
        loadIfNeeded()
        return elements.startIndex
    }

    public __consuming override func makeIterator() -> IndexingIterator<Elements> {
        loadIfNeeded()
        return elements.makeIterator()
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

    // MARK: - Persistant operations

    public override func limit(_ limit: Int) -> Self {
        // TODO handle query with limit
        self.limit = limit
        state = .pending
        return self
    }

    // MARK: - Combine support

    /// Lazy load the collection and expose the loaded `Elements` as a Combine `Publisher`.
    /// This is useful for integrating the `List<ModelType>` with existing Combine code
    /// and/or SwiftUI.
    ///
    /// - Returns: a type-erased Combine publisher
    @available(iOS 13.0, *)
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

    // MARK: ModelListDecoder

    static public func shouldDecode(decoder: Decoder) -> Bool {
        let json = try? JSONValue(from: decoder)
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

    static public func decode<ModelType: Model>(decoder: Decoder, modelType: ModelType.Type) -> List<ModelType> {
        do {
            return try DataStoreList<ModelType>.init(from: decoder)
        } catch {
            return List([ModelType]())
        }
    }

    // MARK: Codable

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
}
