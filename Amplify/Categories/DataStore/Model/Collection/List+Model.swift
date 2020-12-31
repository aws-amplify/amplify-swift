//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine

/// `List<ModelType>` is a custom `Collection` that is capable of loading records from a data source. This is specially
/// useful when dealing with Model associations that need to be lazy loaded. Lazy loading is performed when you access
/// the `Collection` methods by retrieving the data from the underlying data source and then stored into this object,
/// before returning the data to you. Consumers must be aware that multiple calls to the data source and then stored
/// into this object will happen simultaneously if the object is used from different threads, thus not thread safe.
/// Lazy loading is idempotent and will return the stored results on subsequent access.
public class List<ModelType: Model>: Collection, Codable, ExpressibleByArrayLiteral {
    public typealias Index = Int
    public typealias Element = ModelType

    /// Represents the data state of the `List`.
    enum LoadedState {
        case notLoaded
        case loaded([Element])
    }

    /// The current state of lazily loaded list
    var loadedState: LoadedState

    /// The provider for fulfilling list behaviors
    let listProvider: AnyModelListProvider<Element>

    /// The array of `Element` that backs the custom collection implementation.
    ///
    /// Attempting to access the list object will attempt to retrieve the elements in memory or retrieve it from the
    /// provider's data source. This is not thread safe as it can be performed from multiple threads, however the
    /// provider's call to `load` should be idempotent and should result in the final loaded state. An attempt to set
    /// this again will result in no-op and will not overwrite the existing loaded data.
    var elements: [Element] {
        get {
            switch loadedState {
            case .loaded(let elements):
                return elements
            case .notLoaded:
                let result = listProvider.load()
                switch result {
                case .success(let elements):
                    loadedState = .loaded(elements)
                    return elements
                case .failure(let error):
                    Amplify.log.error(error: error)
                    return []
                }
            }
        }
        set {
            switch loadedState {
            case .loaded:
                Amplify.log.error("""
                    There is an attempt to set an already loaded List. The existing data will not be overwritten
                    """)
                return
            case .notLoaded:
                loadedState = .loaded(newValue)
            }
        }
    }

    // MARK: - Initializers

    public init(loadProvider: AnyModelListProvider<ModelType>) {
        self.listProvider = loadProvider
        self.loadedState = .notLoaded
    }

    public convenience init(elements: [Element]) {
        let loadProvider = ArrayLiteralListProvider<ModelType>(elements: elements).eraseToAnyModelListProvider()
        self.init(loadProvider: loadProvider)
    }

    // MARK: - ExpressibleByArrayLiteral

    required convenience public init(arrayLiteral elements: Element...) {
        self.init(elements: elements)
    }

    // MARK: - Collection conformance

    public var startIndex: Index {
        elements.startIndex
    }

    public var endIndex: Index {
        elements.endIndex
    }

    public func index(after index: Index) -> Index {
        elements.index(after: index)
    }

    public subscript(position: Int) -> Element {
        elements[position]
    }

    public __consuming func makeIterator() -> IndexingIterator<[Element]> {
        elements.makeIterator()
    }

    // MARK: - Persistent Operations

    public var totalCount: Int {
        // TODO handle total count
        return 0
    }

    /// `limit` is currently not a supported API.
    @available(*, deprecated, message: "Not supported.")
    public func limit(_ limit: Int) -> Self {
        // TODO handle query with limit
        loadedState = .notLoaded
        return self
    }

    // MARK: - Codable

    /// The decoding logic uses `ModelListDecoderRegistry` to find available decoders to decode to plugin specific
    /// implementations of a `ModelListProvider` for `List<Model>`. The decoders should be added to the registry by the
    /// plugin as part of its configuration steps. By delegating responsibility to the `ModelListDecoder`, it is up to
    /// the plugin to successfully return an instance of `ModelListProvider`.
    required convenience public init(from decoder: Decoder) throws {
        for listDecoder in ModelListDecoderRegistry.listDecoders.get() {
            if listDecoder.shouldDecode(decoder: decoder) {
                let listProvider = try listDecoder.getListProvider(modelType: ModelType.self, decoder: decoder)
                self.init(loadProvider: listProvider)
                return
            }
        }
        let json = try JSONValue(from: decoder)
        if case .array = json {
            let elements = try [Element](from: decoder)
            self.init(elements: elements)
        } else {
            self.init()
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch loadedState {
        case .notLoaded:
            try [Element]().encode(to: encoder)
        case .loaded(let elements):
            try elements.encode(to: encoder)
        }
    }
}
