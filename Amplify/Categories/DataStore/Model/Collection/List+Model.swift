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

    /// The array of `Element` backed by the the custom collection implementation.
    open var elements: Elements {
        fatalError("Not implemented.")
    }
    // MARK: - Initializers

    public init() {

    }

    // MARK: - ExpressibleByArrayLiteral

    required convenience public init(arrayLiteral elements: Element...) {
        self.init()
    }

    // MARK: - Collection conformance

    open var startIndex: Index {
        fatalError("Not implemented.")
    }

    open var endIndex: Index {
        fatalError("Not implemented.")
    }

    open func index(after index: Index) -> Index {
        fatalError("Not implemented.")
    }

    open subscript(position: Int) -> Element {
        fatalError("Not implemented.")
    }

    open __consuming func makeIterator() -> IndexingIterator<Elements> {
        fatalError("Not implemented.")
    }

    // MARK: - Persistent Operations

    open var totalCount: Int {
        // TODO handle total count
        return 0
    }

    /// `limit` is currently not a supported API. Calling this API will always crash.
    @available(*, deprecated, message: "Not supported. Your app will crash if called.")
    open func limit(_ limit: Int) -> Self {
        fatalError("Not supported.")
    }

    // MARK: - Codable

    /// The decoding logic uses `ModelListDecoderRegistry` to find available decoders to decode to plugin specific
    /// implementations of `List<Model>`. The decoders should be added to the registry by the plugin as part of its
    /// configuration steps. By delegating responsibility to the `ModelListDecoder`, it is up to the plugin to
    /// successfully return an instantiated subclass of `List`. A fatal error is thrown when a decoder indicates it is
    /// able to decode but fails to decode successfully.
    required convenience public init(from decoder: Decoder) throws {
        for listDecoder in ModelListDecoderRegistry.listDecoders {
            if listDecoder.shouldDecode(decoder: decoder) {
                guard let list = try listDecoder.decode(decoder: decoder, modelType: ModelType.self) as? Self else {
                    fatalError("Failed to decode using ModelListDecoderRegistry's decoders.")
                }

                self.init(factory: { list })
                return
            }
        }

        self.init()
    }

    open func encode(to encoder: Encoder) throws {
        let elements = [ModelType]()
        try elements.encode(to: encoder)
    }

    // MARK: - Asynchronous API

    /// Call this to initialize the collection if you have retrieved the list by traversing from your model objects
    /// to its associated children objects. For example, a Post model may contain a list of Comments. By retrieving the
    /// post object and trvasering to the comments, the comments are not retrieved from the data source until this
    /// method is called. Data will be retrieved based on the plugin's data source and may have different failure
    /// conditions, such as one that requires connectivity may fail with a network error. You can alternatively access
    /// the Collection methods on the list to trigger the retrieval of data, but also expect that any operation to
    /// perform as fast as it takes to make a request to the datastore and back.
    ///
    /// If you have directly created this list object then the collection has already been initialized and calling this
    /// method will have no effect. For example, when you directly retrieve a list of comments by its post id, upon
    /// success the collection will be initialized with the data.
    open func load(_ completion: DataStoreCallback<Elements>) {
        fatalError("Not implemented.")
    }

    // MARK: - Synchronous API

    /// Load data into the collection from the data source. This method blocks until data is loaded. When operating on
    /// large result sets, prefer using the asynchronous `load(completion:)` instead.
    ///
    /// - Returns: the current instance after data was loaded.
    /// - seealso: `load(completion:)`
    open func load() -> Self {
        fatalError("Not implemented.")
    }

    // MARK: Combine

    /// Load data into the collection from the data source and expose the data as a Combine `Publisher`. This is useful
    /// for integrating the `List<ModelType>` with existing Combine code and/or SwiftUI. This method has been deprecated
    /// and is currently not a supported API.
    ///
    ///
    /// - Returns: a type-erased Combine publisher
    @available(iOS 13.0, *)
    @available(*, deprecated, message: "Use `load` instead.")
    open func loadAsPublisher() -> LazyListPublisher {
        fatalError("Not supported.")
    }
}
