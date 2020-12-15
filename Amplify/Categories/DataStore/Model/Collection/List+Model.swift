//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine

/// `List<ModelType>` is a custom `Collection` that is capable of loading
/// records from a datasource. This is specially useful when dealing with
/// Model associations that need to be lazy loaded.
open class List<ModelType: Model>: ModelList {

    @available(iOS 13.0, *)
    public typealias LazyListPublisher = AnyPublisher<Elements, DataStoreError>

    public typealias Index = Int
    public typealias Element = ModelType
    public typealias Elements = [Element]

    public typealias ArrayLiteralElement = ModelType

    /// The array of `Element` that backs the custom collection implementation.
    public var elements: Elements

    // MARK: - Initializers

    public init(_ elements: Elements) {
        self.elements = elements
    }

    // MARK: - ExpressibleByArrayLiteral

    required convenience public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }

    // MARK: - Collection conformance

    open var startIndex: Index {
        return elements.startIndex
    }

    open var endIndex: Index {
        return elements.endIndex
    }

    open func index(after index: Index) -> Index {
        return elements.index(after: index)
    }

    open subscript(position: Int) -> Element {
        return elements[position]
    }

    open __consuming func makeIterator() -> IndexingIterator<Elements> {
        return elements.makeIterator()
    }

    // MARK: - Persistent Operations

    open var totalCount: Int {
        // TODO handle total count
        return 0
    }

    @available(*, deprecated, message: "Not supported.")
    open func limit(_ limit: Int) -> Self {
        fatalError("Not implemented")
    }

    // MARK: - Codable

    required convenience public init(from decoder: Decoder) throws {
        for listDecoder in ModelListDecoderRegistry.listDecoders {
            if listDecoder.shouldDecode(decoder: decoder) {
                guard let list = listDecoder.decode(decoder: decoder, modelType: ModelType.self) as? Self else {
                    fatalError("Failed to decode using ModelListDecoderRegistry's decoders.")
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

    // MARK: - Asynchronous API

    /// Use to initialize the collection.
    ///
    /// - seealso: `load()`
    open func load(_ completion: DataStoreCallback<Elements>) {
        fatalError("Not implemented.")
    }

    // MARK: - Synchronous API

    /// Use to initialize the collection. Consumers must be aware of
    /// the internal behavior that may block until data is ready. When operating on large result
    /// sets, prefer using the asynchronous `load(completion:)` instead.
    ///
    /// - Returns: the current instance after data was loaded.
    /// - seealso: `load(completion:)`
    open func load() -> Self {
        fatalError("Not implemented.")
    }

    // MARK: Combine

    /// Lazy load the collection and expose the loaded `Elements` as a Combine `Publisher`.
    /// This is useful for integrating the `List<ModelType>` with existing Combine code
    /// and/or SwiftUI.
    ///
    /// - Returns: a type-erased Combine publisher
    @available(iOS 13.0, *)
    @available(*, deprecated, message: "Use `load` instead.")
    open func loadAsPublisher() -> LazyListPublisher {
        fatalError("Not implemented")
    }
}
