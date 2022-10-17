//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine

public class LazyModel<Element: Model>: Codable, LazyModelMarker {
    
    /// Represents the data state of the `LazyModel`.
    enum LoadedState {
        case notLoaded(identifiers: [String: String])
        case loaded(Element?)
    }
    var loadedState: LoadedState
    
    /// The provider for fulfilling list behaviors
    let modelProvider: AnyModelProvider<Element>
    
    public internal(set) var element: Element? {
        get {
            switch loadedState {
            case .notLoaded:
                return nil
            case .loaded(let element):
                return element
            }
        }
        set {
            switch loadedState {
            case .loaded:
                Amplify.log.error("""
                    There is an attempt to set an already lazy model. The existing data will not be overwritten
                    """)
                return
            case .notLoaded:
                loadedState = .loaded(newValue)
            }
        }
    }
    public init(modelProvider: AnyModelProvider<Element>) {
        self.modelProvider = modelProvider
        switch self.modelProvider.getState() {
        case .loaded(let element):
            self.loadedState = .loaded(element)
        case .notLoaded(let identifiers):
            self.loadedState = .notLoaded(identifiers: identifiers)
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
        case .notLoaded(let identifiers):
            var container = encoder.singleValueContainer()
            try container.encode(identifiers)
        case .loaded(let element):
            try element.encode(to: encoder)
        }
    }
    
    // MARK: - APIs
    
    public func get() async throws -> Element? {
        switch loadedState {
        case .notLoaded:
            let element = try await modelProvider.load()
            self.loadedState = .loaded(element)
            return element
        case .loaded(let element):
            return element
        }
    }
}
