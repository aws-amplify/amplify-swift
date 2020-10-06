//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Provides page related functionality when conforming to `Paginatable` from an API Category plugin.
public protocol Paginatable {

    associatedtype Page

    typealias PageResult = ((Result<Page, APIError>) -> Void)

    /// Checks if there is subsequent data.
    func hasNextPage() -> Bool

    /// Retrieves the next set of data, limited to the `limit` number of results, when completed will be returned as
    /// a `Page` on `onComplete` closure.
    func getNextPage(limit: Int?, onComplete: @escaping PageResult)
}

/// Methods related to lazy loading data
public protocol LazyLoad {
    // Persistant operation to set the size for lazy loading of data.
    func limit(_ limit: Int) -> Self
}

/// Empty protocol used as a marker for plugins to detect `ModelList` conformance. `ModelList` cannot be used directly
/// since it has associated type requirements.
public protocol ModelListMarker { }

/// `ModelList` is a custom `Collection` of
public protocol ModelList: Collection,
                           Codable,
                           ExpressibleByArrayLiteral,
                           Paginatable,
                           LazyLoad,
                           ModelListMarker where Element == ModelListElement,
                                                 Index == Int,
                                                 ArrayLiteralElement == ModelListElement {
    associatedtype ModelListElement: Model

    init(factory: () -> Self)

}

extension ModelList {
    /// Initializer useful in the decoder to instantiate Self as a subclass of classes conforming to `ModelList`
    /// conforming to `ModelList`
    public init(factory: () -> Self) {
        self = factory()
    }
}

/// Registry of `ModelListDecoder`'s used to retrieve decoders for checking if decodable to type of `List<ModelType>`.
public struct ModelListDecoderRegistry {
    public static var listDecoders: [ModelListDecoder.Type] = []

    /// Register a decoder at plugin configuration to be used for custom decoding to plugin subclasses of
    /// `List<ModelType>`.
    public static func registerDecoder(_ listDecoder: ModelListDecoder.Type) {
        listDecoders.append(listDecoder)
    }
}

/// `ModelListDecoder` provides decodability checking and decoding functionality.
public protocol ModelListDecoder {
    static func shouldDecode(decoder: Decoder) -> Bool
    static func decode<ModelType: Model>(decoder: Decoder,
                                         modelType: ModelType.Type) -> List<ModelType>

}

/// `List<ModelType>` is a custom `Collection` for accessing `Model` elements. It provides basic JSON array decoding,
/// `Collection`, and `ExpressibleByArrayLiteral` conformance to access an array of `Model` elements. It does not
/// provide `Paginatable` and `LazyLoad` conformance and is implemented by the plugin specific subclass of
/// `List<ModelType>`.
///
/// The decoding logic uses `ModelListRegistry` to check for decodability and vends instances of subclasses of
/// `List<ModelType>` to instantiate itself to provide plugin specific capabilities.
open class List<ModelType: Model>: ModelList {
    public typealias ModelListElement = ModelType
    public typealias Page = List<ModelType>
    public typealias Element = ModelType
    public typealias Elements = [Element]

    /// The array of `Element` that backs the custom collection implementation.
    internal var elements: Elements

    // MARK: - Initializers

    public init(_ elements: Elements) {
        self.elements = elements
    }

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

    // MARK: Persistant operations

    @available(*, deprecated, message: "Not supported.")
    public var totalCount: Int {
        // TODO handle total count
        return 0
    }

    // MARK: Paginatable

    open func hasNextPage() -> Bool {
        return false
    }

    open func getNextPage(limit: Int? = nil, onComplete: @escaping PageResult) {
        fatalError("Not supported")
    }

    // MARK: LazyLoad

    open func limit(_ limit: Int) -> Self {
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
