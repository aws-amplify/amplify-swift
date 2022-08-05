//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine

/// Empty protocol used as a marker to detect when the type is a `List`
///
/// - Warning: Although this has `public` access, it is intended for internal & codegen use and should not be used
/// directly by host applications. The behavior of this may change without warning. Though it is not used by host
/// application making any change to these `public` types should be backward compatible, otherwise it will be a breaking
/// change.
public protocol ModelListMarker { }

/// State of the ListProvider
///
/// - Warning: Although this has `public` access, it is intended for internal & codegen use and should not be used
/// directly by host applications. The behavior of this may change without warning. Though it is not used by host
/// application making any change to these `public` types should be backward compatible, otherwise it will be a breaking
/// change.
public enum ModelListProviderState<Element: Model> {
    case notLoaded
    case loaded([Element])
}

/// - Warning: Although this has `public` access, it is intended for internal & codegen use and should not be used
/// directly by host applications. The behavior of this may change without warning. Though it is not used by host
/// application making any change to these `public` types should be backward compatible, otherwise it will be a breaking
/// change.
public protocol ModelListProvider {
    associatedtype Element: Model

    func getState() -> ModelListProviderState<Element>
    
    ///  Retrieve the array of `Element` from the data source asychronously.
    func load(completion: @escaping (Result<[Element], CoreError>) -> Void)

    /// Check if there is subsequent data to retrieve. This method always returns false if the underlying provider is
    /// not loaded. Make sure the underlying data is loaded by calling `load(completion)` before calling this method.
    /// If true, the next page can be retrieved using `getNextPage(completion:)`.
    func hasNextPage() -> Bool

    /// Asynchronously retrieve the next page as a new in-memory List object. Returns a failure if there
    /// is no next page of results. You can validate whether the list has another page with `hasNextPage()`.
    func getNextPage(completion: @escaping (Result<List<Element>, CoreError>) -> Void)
}

/// - Warning: Although this has `public` access, it is intended for internal & codegen use and should not be used
/// directly by host applications. The behavior of this may change without warning. Though it is not used by host
/// application making any change to these `public` types should be backward compatible, otherwise it will be a breaking
/// change.
public struct AnyModelListProvider<Element: Model>: ModelListProvider {
    private let getStateClosure: () -> ModelListProviderState<Element>
    private let loadWithCompletionClosure: (@escaping (Result<[Element], CoreError>) -> Void) -> Void
    private let hasNextPageClosure: () -> Bool
    private let getNextPageClosure: (@escaping (Result<List<Element>, CoreError>) -> Void) -> Void

    public init<Provider: ModelListProvider>(
        provider: Provider
    ) where Provider.Element == Self.Element {
        self.getStateClosure = provider.getState
        self.loadWithCompletionClosure = provider.load(completion:)
        self.hasNextPageClosure = provider.hasNextPage
        self.getNextPageClosure = provider.getNextPage(completion:)
    }

    public func getState() -> ModelListProviderState<Element> {
        getStateClosure()
    }
    
    public func load(completion: @escaping (Result<[Element], CoreError>) -> Void) {
        loadWithCompletionClosure(completion)
    }

    public func hasNextPage() -> Bool {
        hasNextPageClosure()
    }

    public func getNextPage(completion: @escaping (Result<List<Element>, CoreError>) -> Void) {
        getNextPageClosure(completion)
    }
}

/// - Warning: Although this has `public` access, it is intended for internal & codegen use and should not be used
/// directly by host applications. The behavior of this may change without warning. Though it is not used by host
/// application making any change to these `public` types should be backward compatible, otherwise it will be a breaking
/// change.
public extension ModelListProvider {
    func eraseToAnyModelListProvider() -> AnyModelListProvider<Element> {
        AnyModelListProvider(provider: self)
    }
}
