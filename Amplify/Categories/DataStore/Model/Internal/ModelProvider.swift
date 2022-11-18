//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol LazyReferenceMarker {
    associatedtype ModelType: Model
    
    var reference: ModelType? { get }
    
    var identifiers: [LazyReferenceIdentifier]? { get }
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
    case notLoaded(identifiers: [LazyReferenceIdentifier]?)
    case loaded(Element?)
}

// MARK - AnyModelProvider

public extension ModelProvider {
    func eraseToAnyModelProvider() -> AnyModelProvider<Element> {
        AnyModelProvider(provider: self)
    }
}
