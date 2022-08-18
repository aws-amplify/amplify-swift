//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine

public class LazyModel<Element: Model>: Codable {
    /// Represents the data state of the `List`.
    enum LoadedState {
        case notLoaded
        case loaded(Element?)
    }
    var loadedState: LoadedState
    
    /// The provider for fulfilling list behaviors
    let modelProvider: AnyModelProvider<Element>
    
    public init(modelProvider: AnyModelProvider<Element>) {
        self.modelProvider = modelProvider
        switch self.modelProvider.getState() {
        case .loaded(let element):
            self.loadedState = .loaded(element)
        case .notLoaded:
            self.loadedState = .notLoaded
        }
    }
    
    public convenience init(element: Element? = nil) {
        let modelProvider = DefaultModelProvider(element: element).eraseToAnyModelProvider()
        self.init(modelProvider: modelProvider)
    }
    
    required convenience public init(from decoder: Decoder) throws {
        for modelDecoder in ModelProviderRegistry.decoders.get() {
            if modelDecoder.shouldDecode(modelType: Element.self, decoder: decoder) {
                let modelProvider = try modelDecoder.makeModelProvider(modelType: Element.self, decoder: decoder)
                self.init(modelProvider: modelProvider)
                return
            }
        }
        let json = try JSONValue(from: decoder)
        if case .object = json {
            let element = try Element(from: decoder)
            self.init(element: element)
        } else {
            self.init()
        }
    }
    
    
    public func encode(to encoder: Encoder) throws {
        switch loadedState {
        case .notLoaded:
            break
            // try Element.encode(to: encoder)
        case .loaded(let element):
            try element.encode(to: encoder)
        }
    }
    
    // MARK: - APIs
    
    public func get() async throws -> Element? {
        switch loadedState {
        case .notLoaded:
            return nil
        case .loaded(let element):
            return element
        }
    }
}

public struct AnyModelProvider<Element: Model>: ModelProvider {
    
    private let loadAsync: () async throws -> Element?
    private let getStateClosure: () -> ModelProviderState<Element>
    
    public init<Provider: ModelProvider>(provider: Provider) where Provider.Element == Self.Element {
        self.loadAsync = provider.load
        self.getStateClosure = provider.getState
    }
    public func load() async throws -> Element? {
        try await loadAsync()
    }
    
    public func getState() -> ModelProviderState<Element> {
        getStateClosure()
    }
}

public protocol ModelProvider {
    associatedtype Element: Model
    
    func load() async throws -> Element?
    
    func getState() -> ModelProviderState<Element>

}

public enum ModelProviderState<Element: Model> {
    case notLoaded(id: String, field: String)
    case loaded(Element?)
}

/// `List<ModelType>` is a custom `Collection` that is capable of loading records from a data source. This is especially
/// useful when dealing with Model associations that need to be lazy loaded. Lazy loading is performed when you access
/// the `Collection` methods by retrieving the data from the underlying data source and then stored into this object,
/// before returning the data to you. Consumers must be aware that multiple calls to the data source and then stored
/// into this object will happen simultaneously if the object is used from different threads, thus not thread safe.
/// Lazy loading is idempotent and will return the stored results on subsequent access.
public class List<ModelType: Model>: Collection, Codable, ExpressibleByArrayLiteral, ModelListMarker {
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
    public internal(set) var elements: [Element] {
        get {
            switch loadedState {
            case .loaded(let elements):
                return elements
            case .notLoaded:
                let message = "Call `fetch` to lazy load the list before accessing `elements`."
                Amplify.log.error(message)
                assertionFailure(message)
                return []
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

    public init(listProvider: AnyModelListProvider<ModelType>) {
        self.listProvider = listProvider
        switch self.listProvider.getState() {
        case .loaded(let elements):
            self.loadedState = .loaded(elements)
        case .notLoaded:
            self.loadedState = .notLoaded
        }
    }

    public convenience init(elements: [Element]) {
        let loadProvider = ArrayLiteralListProvider<ModelType>(elements: elements).eraseToAnyModelListProvider()
        self.init(listProvider: loadProvider)
    }

    // MARK: - ExpressibleByArrayLiteral

    required convenience public init(arrayLiteral elements: Element...) {
        self.init(elements: elements)
    }

    // MARK: - Collection conformance

    /// Accessing the elements on a list that has not been loaded yet will operate slower than O(1) as the data will be
    /// retrieved synchronously as part of this call.
    public var startIndex: Index {
        elements.startIndex
    }

    /// Accessing the elements on a list that has not been loaded yet will operate slower than O(1) as the data will be
    /// retrieved synchronously as part of this call.
    public var endIndex: Index {
        elements.endIndex
    }

    /// Accessing the elements on a list that has not been loaded yet will operate slower than O(1) as the data will be
    /// retrieved synchronously as part of this call.
    public func index(after index: Index) -> Index {
        elements.index(after: index)
    }

    /// Accessing the elements on a list that has not been loaded yet will operate slower than O(1) as the data will be
    /// retrieved synchronously as part of this call.
    public subscript(position: Int) -> Element {
        elements[position]
    }

    /// Accessing the elements on a list that has not been loaded yet will operate slower than O(1) as the data will be
    /// retrieved synchronously as part of this call.
    public __consuming func makeIterator() -> IndexingIterator<[Element]> {
        elements.makeIterator()
    }

    /// Accessing the elements on a list that has not been loaded yet will operate slower than O(1) as the data will be
    /// retrieved synchronously as part of this call.
    public var count: Int {
        elements.count
    }

    // MARK: - Persistent Operations

    public var totalCount: Int {
        // TODO handle total count
        return 0
    }

    /// `limit` is currently not a supported API.
    @available(*, deprecated, message: "Not supported.")
    public func limit(_ limit: Int) -> Self {
        return self
    }

    // MARK: - Codable

    /// The decoding logic uses `ModelListDecoderRegistry` to find available decoders to decode to plugin specific
    /// implementations of a `ModelListProvider` for `List<Model>`. The decoders should be added to the registry by the
    /// plugin as part of its configuration steps. By delegating responsibility to the `ModelListDecoder`, it is up to
    /// the plugin to successfully return an instance of `ModelListProvider`.
    required convenience public init(from decoder: Decoder) throws {
        for listDecoder in ModelListDecoderRegistry.listDecoders.get() {
            if listDecoder.shouldDecode(modelType: ModelType.self, decoder: decoder) {
                let listProvider = try listDecoder.makeListProvider(modelType: ModelType.self, decoder: decoder)
                self.init(listProvider: listProvider)
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
