//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import Amplify

extension Swift.Result {

    @discardableResult
    func ifSuccess(_ execute: (Success) -> Void) -> Swift.Result<Success, Failure> {
        if case let .success(value) = self {
            execute(value)
        }
        return self
    }

    @discardableResult
    func ifFailure(_ execute: (Failure) -> Void) -> Swift.Result<Success, Failure> {
        if case let .failure(error) = self {
            execute(error)
        }
        return self
    }

    // drop success information
    func dropSuccessValue() -> Swift.Result<Void, Failure> {
        self.map { _ in () }
    }

    // drop failure information
    func toOptional() -> Success? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }

    func tryMap<NewSuccess>(
        _ transform: (Success) throws -> NewSuccess
    ) -> Swift.Result<NewSuccess, Failure> where Failure == DataStoreError {
        switch self {
        case .success(let value):
            do {
                return .success(try transform(value))
            } catch {
                return .failure(DataStoreError(error: error))
            }
        case .failure(let error):
            return .failure(error)
        }
    }
}
