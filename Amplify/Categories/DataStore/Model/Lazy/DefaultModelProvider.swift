//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// MARK: - DefaultModelProvider

public struct DefaultModelProvider<Element: Model>: ModelProvider {
   
    let element: Element?
    public init(element: Element? = nil) {
        self.element = element
    }
    
    public func load() async throws -> Element? {
        return element
    }
    
    public func getState() -> ModelProviderState<Element> {
        return .loaded(element)
    }
    
}
