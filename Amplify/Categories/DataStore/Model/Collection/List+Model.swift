//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine

public typealias ListCallback<Result> = (ListResult<Result>) -> Void
public typealias ListResult<Success> = Result<Success, CoreError>

/// `List<ModelType>` provides simple conformance to `Collection` with a backing array of `Model` type elements.
/// This class acts as an abstract class for plugins to build subclasses that implement their own specific
/// implementations of a `ModelList`. The decoding logic leverages the `ModelListRegistry` to check for decodability
/// and decodes to subclasses of this type.
open class List<ModelType: Model>: ModelList {
    @available(iOS 13.0, *)
    public typealias LazyListPublisher = AnyPublisher<Elements, DataStoreError>

    public typealias ModelListElement = ModelType
    public typealias Element = ModelType
    public typealias Elements = [Element]

    /// The array of `Element` that backs the custom collection implementation.
    public var elements: Elements

    // MARK: - Initializers

    public init(_ elements: Elements) {
        self.elements = elements
    }

    // MARK: - ExpressibleByArrayLiteral

    public required convenience init(arrayLiteral elements: ModelType...) {
        self.init(elements)
    }

    // MARK: - Collection conformance

    open var startIndex: Int {
        elements.startIndex
    }

    open var endIndex: Int {
        elements.endIndex
    }

    open func index(after index: Index) -> Index {
        elements.index(after: index)
    }

    open subscript(position: Int) -> Element {
        elements[position]
    }

    open __consuming func makeIterator() -> IndexingIterator<Elements> {
        elements.makeIterator()
    }

    // MARK: - Persistant operations

    public var totalCount: Int {
        // TODO handle total count
        return 0
    }

    @available(*, deprecated, message: "Not supported.")
    open func limit(_ limit: Int) -> Self {
        return self
    }

    // MARK: - Asynchronous API

    /// Trigger `DataStore` query to initialize the collection. This function always
    /// fetches data from the `DataStore.query`.
    ///
    /// - seealso: `load()`
    @available(*, deprecated, message: "Use `fetch` instead.")
    open func load(_ completion: DataStoreCallback<Elements>) {
        fatalError("Not supported")
    }

    /// Trigger a query to initialize the collection. This function always
    /// fetches data from the backing data store if the collectino has not yet been loaded
    ///
    /// - seealso: `load()`
    open func fetch(_ completion: @escaping ListCallback<Elements>) {
        fatalError("Not supported")
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
    @available(*, deprecated, message: "Use `fetch` instead.")
    open func load() -> Self {
        fatalError("Not supported")
    }

    // MARK: - Combine support

    /// Lazy load the collection and expose the loaded `Elements` as a Combine `Publisher`.
    /// This is useful for integrating the `List<ModelType>` with existing Combine code
    /// and/or SwiftUI.
    ///
    /// - Returns: a type-erased Combine publisher
    @available(iOS 13.0, *)
    @available(*, deprecated, message: "Use `fetch` instead.")
    open func loadAsPublisher() -> LazyListPublisher {
        fatalError("Not supported")
    }

    // MARK: Paginatable

    open func hasNextPage() -> Bool {
        return false
    }

    open func getNextPage(completion: @escaping (Result<List<Element>, CoreError>) -> Void) {
        fatalError("Not supported")
    }

    // MARK: - Codable

    required convenience public init(from decoder: Decoder) throws {
        for listDecoder in ModelListDecoderRegistry.listDecoders {
            if listDecoder.shouldDecode(decoder: decoder) {
                guard let list = listDecoder.decode(decoder: decoder, modelType: ModelType.self) as? Self else {
                    fatalError("Failed to decode")
                }

                self.init(factory: { list })
                return
            }
        }

        let json = try JSONValue(from: decoder)

        switch json {
        case .array:
            let elements = try Elements(from: decoder)
            self.init(elements)
        default:
            self.init(Elements())
        }
    }

    public func encode(to encoder: Encoder) throws {
        try elements.encode(to: encoder)
    }
}
