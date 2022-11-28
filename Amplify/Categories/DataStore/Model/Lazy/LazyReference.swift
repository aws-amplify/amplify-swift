//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine

/// A Codable struct to hold key value pairs representing the identifier's field name and value.
/// Useful for maintaining order for key-value pairs when used as an Array type.
public struct LazyReferenceIdentifier: Codable {
    public let name: String
    public let value: String
    
    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

/// This class represents a lazy reference to a `Model`, meaning that the reference
/// may or may not exist at instantiation time.
///
/// The default implementation `DefaultModelProvider` only handles in-memory data, therefore `get()` and
/// `require()` will simply return the current `reference`.
public class LazyReference<ModelType: Model>: Codable, LazyReferenceValue {
    
    /// Represents the data state of the `LazyModel`.
    enum LoadedState {
        case notLoaded(identifiers: [LazyReferenceIdentifier]?)
        case loaded(ModelType?)
    }
    
    var loadedState: LoadedState
    
    public var state: LazyReferenceValueState {
        switch loadedState {
        case .notLoaded(let identifiers):
            return .notLoaded(identifiers: identifiers)
        case .loaded(let model):
            return .loaded(model: model)
        }
    }
    
    /// The provider for fulfilling list behaviors
    let modelProvider: AnyModelProvider<ModelType>
    
    public var identifiers: [LazyReferenceIdentifier]? {
        get {
            switch loadedState {
            case .notLoaded(let identifiers):
                return identifiers
            case .loaded:
                return nil
            }
        }
    }
    
    public init(modelProvider: AnyModelProvider<ModelType>) {
        self.modelProvider = modelProvider
        switch self.modelProvider.getState() {
        case .loaded(let element):
            self.loadedState = .loaded(element)
        case .notLoaded(let identifiers):
            self.loadedState = .notLoaded(identifiers: identifiers)
        }
    }
    
    // MARK: - Initializers
    
    public convenience init(_ reference: ModelType?) {
        let modelProvider = DefaultModelProvider(element: reference).eraseToAnyModelProvider()
        self.init(modelProvider: modelProvider)
    }
    
    public convenience init(identifiers: [LazyReferenceIdentifier]?) {
        let modelProvider = DefaultModelProvider<ModelType>(identifiers: identifiers).eraseToAnyModelProvider()
        self.init(modelProvider: modelProvider)
    }
    
    // MARK: - Codable implementation
    
    /// Decodable implementation is delegated to the underlying `self.reference`.
    required convenience public init(from decoder: Decoder) throws {
        for modelDecoder in ModelProviderRegistry.decoders.get() {
            if modelDecoder.shouldDecode(modelType: ModelType.self, decoder: decoder) {
                let modelProvider = try modelDecoder.makeModelProvider(modelType: ModelType.self, decoder: decoder)
                self.init(modelProvider: modelProvider)
                return
            }
        }
        let json = try JSONValue(from: decoder)
        if case .object = json {
            let element = try ModelType(from: decoder)
            self.init(element)
        } else {
            self.init(identifiers: nil)
        }
    }
    
    /// Encodable implementation is delegated to the underlying `self.reference`.
    public func encode(to encoder: Encoder) throws {
        switch loadedState {
        case .notLoaded(let identifiers):
            var container = encoder.singleValueContainer()
            try container.encode(identifiers)
        case .loaded(let element):
            try element.encode(to: encoder)
        }
    }
    
    // MARK: - APIs
    
    /// This function is responsible for retrieving the model reference. In the default
    /// implementation this means simply returning the existing `reference`, but different
    /// storage mechanisms can implement their own logic to fetch data,
    /// e.g. from DataStore's SQLite or AppSync.
    ///
    /// - Returns: the model `reference`, if it exists.
    public func get() async throws -> ModelType? {
        switch loadedState {
        case .notLoaded:
            let element = try await modelProvider.load()
            self.loadedState = .loaded(element)
            return element
        case .loaded(let element):
            return element
        }
    }
    
    /// The equivalent of `get()` but aimed to retrieve references that are considered
    /// non-optional. However, referential integrity issues and/or availability constraints
    /// might affect how required data is fetched. In such scenarios the implementation
    /// must throw an error to communicate to developers why required data could not be fetched.
    ///
    /// - Throws: an error of type `DataError` when the data marked as required cannot be retrieved.
    public func require() async throws -> ModelType {
        switch loadedState {
        case .notLoaded:
            guard let element = try await modelProvider.load() else {
                // TODO: based on PR review, we may change all CoreError's to DataError's.
                throw CoreError.operation("Expected required element not found", "", nil)
            }
            self.loadedState = .loaded(element)
            return element
        case .loaded(let element):
            guard let element = element else {
                // TODO: based on PR review, we may change all CoreError's to DataError's.
                // throw CoreError.operation("Expected required element not found", "", nil)
                throw DataError.dataUnavailable
            }
            return element
        }
    }
}
