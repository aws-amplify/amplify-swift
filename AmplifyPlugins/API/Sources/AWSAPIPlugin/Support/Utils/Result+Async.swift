//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation

extension Result {
    func flatMapAsync<NewSuccess>(_ f: (Success) async -> Result<NewSuccess, Failure>) async -> Result<NewSuccess, Failure> {
        switch self {
        case .success(let value):
            return await f(value)
        case .failure(let error):
            return .failure(error)
        }
    }
}
