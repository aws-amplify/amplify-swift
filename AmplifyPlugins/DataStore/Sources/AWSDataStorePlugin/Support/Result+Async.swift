//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation

extension Swift.Result {

    func flatMapAsync<NewSuccess>(
        _ transform: (Success) async -> Swift.Result<NewSuccess, Failure>
    ) async -> Swift.Result<NewSuccess, Failure> {
        switch self {
        case let .success(value):
            return await transform(value)
        case let .failure(error):
            return .failure(error)
        }
    }

}
