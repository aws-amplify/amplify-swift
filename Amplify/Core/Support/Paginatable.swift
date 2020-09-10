//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol Paginatable {
    associatedtype Page
    associatedtype PageError: Error
    typealias PageResult = ((Result<Page, PageError>) -> Void)
    func next(onComplete: @escaping PageResult)
    func hasNext() -> Bool
}
