//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class AppSyncListProvider<Element: Model>: ModelListProvider {
    var elements: [Element]

    init(_ elements: [Element]) {
        self.elements = elements
    }

    public func load() -> Result<[Element], CoreError> {
        .success(elements)
    }

    public func load(completion: (Result<[Element], CoreError>) -> Void) {
        completion(.success(elements))
    }

    public func hasNextPage() -> Bool {
        fatalError("Not implemented.")
    }

    public func getNextPage(completion: (Result<List<Element>, CoreError>) -> Void) {
        fatalError("Not implemented.")
    }
}
