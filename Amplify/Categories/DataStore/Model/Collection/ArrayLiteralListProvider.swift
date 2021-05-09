//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine

/// <#Description#>
public struct ArrayLiteralListProvider<Element: Model>: ModelListProvider {

    /// <#Description#>
    let elements: [Element]

    /// <#Description#>
    /// - Parameter elements: <#elements description#>
    public init(elements: [Element]) {
        self.elements = elements
    }

    /// <#Description#>
    /// - Returns: <#description#>
    public func load() -> Result<[Element], CoreError> {
        .success(elements)
    }

    /// <#Description#>
    /// - Parameter completion: <#completion description#>
    public func load(completion: @escaping (Result<[Element], CoreError>) -> Void) {
        completion(.success(elements))
    }

    /// <#Description#>
    /// - Returns: <#description#>
    public func hasNextPage() -> Bool {
        false
    }

    /// <#Description#>
    /// - Parameter completion: <#completion description#>
    public func getNextPage(completion: @escaping (Result<List<Element>, CoreError>) -> Void) {
        completion(.failure(CoreError.clientValidation("No pagination on an array literal",
                                                       "Don't call this method",
                                                       nil)))
    }
}
