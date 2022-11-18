//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Protocol used as a marker to detecth when the type is a `LazyReference`.
/// Useful to extract out the `reference` or the identifiers of the Model.
///
/// - Warning: Although this has `public` access, it is intended for internal & codegen use and should not be used
/// directly by host applications. The behavior of this may change without warning. Though it is not used by host
/// application making any change to these `public` types should be backward compatible, otherwise it will be a breaking
/// change.
public protocol LazyReferenceMarker {
    associatedtype ModelType: Model
    
    var reference: ModelType? { get }
    
    var identifiers: [LazyReferenceIdentifier]? { get }
}

/// State of the ModelProvider
///
/// - Warning: Although this has `public` access, it is intended for internal & codegen use and should not be used
/// directly by host applications. The behavior of this may change without warning. Though it is not used by host
/// application making any change to these `public` types should be backward compatible, otherwise it will be a breaking
/// change.
public enum ModelProviderState<Element: Model> {
    case notLoaded(identifiers: [LazyReferenceIdentifier]?)
    case loaded(Element?)
}

/// - Warning: Although this has `public` access, it is intended for internal & codegen use and should not be used
/// directly by host applications. The behavior of this may change without warning. Though it is not used by host
/// application making any change to these `public` types should be backward compatible, otherwise it will be a breaking
/// change.
public protocol ModelProvider {
    associatedtype Element: Model
    
    func load() async throws -> Element?
    
    func getState() -> ModelProviderState<Element>
}

/// - Warning: Although this has `public` access, it is intended for internal & codegen use and should not be used
/// directly by host applications. The behavior of this may change without warning. Though it is not used by host
/// application making any change to these `public` types should be backward compatible, otherwise it will be a breaking
/// change.
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

/// - Warning: Although this has `public` access, it is intended for internal & codegen use and should not be used
/// directly by host applications. The behavior of this may change without warning. Though it is not used by host
/// application making any change to these `public` types should be backward compatible, otherwise it will be a breaking
/// change.
public extension ModelProvider {
    func eraseToAnyModelProvider() -> AnyModelProvider<Element> {
        AnyModelProvider(provider: self)
    }
}
