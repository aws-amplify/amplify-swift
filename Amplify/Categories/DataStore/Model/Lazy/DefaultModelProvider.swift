//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// MARK: - DefaultModelProvider
public struct DefaultModelProvider<Element: Model>: ModelProvider {

    var loadedState: ModelProviderState<Element>

    public init(element: Element? = nil) {
        self.loadedState = .loaded(model: element)
    }

    public init(identifiers: [LazyReferenceIdentifier]?) {
        self.loadedState = .notLoaded(identifiers: identifiers)
    }

    @available(iOS 13.0.0, *)
    public func load() async throws -> Element? {
        switch loadedState {
        case .notLoaded:
            return nil
        case .loaded(let model):
            return model
        }
    }

    public func getState() -> ModelProviderState<Element> {
        loadedState
    }

    public func encode(to encoder: Encoder) throws {
        switch loadedState {
        case .notLoaded(let identifiers):
            var container = encoder.singleValueContainer()
            try container.encode(identifiers)
        case .loaded(let element):
            try element.encode(to: encoder)
        }
    }
}
