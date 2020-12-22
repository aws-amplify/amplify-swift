//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol Paginatable {

    typealias PageResultCallback = (Result<List<Element>, CoreError>) -> Void
    associatedtype Element: Model

    /// Checks if there is subsequent data to retrieve. If True, retrieve the next page using `getNextPage`
    func hasNextPage() -> Bool

    /// Retrieves the next page as a new in-memory List object asynchronously.
    func getNextPage(completion: @escaping PageResultCallback)
}
