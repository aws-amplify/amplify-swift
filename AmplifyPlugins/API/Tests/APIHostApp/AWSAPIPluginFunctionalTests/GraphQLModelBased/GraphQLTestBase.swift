//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify

class GraphQLTestBase: XCTestCase {
    func mutateModel<M: Model>(request: GraphQLRequest<M>) -> Result<M, Error> {
        let mutateFinished = expectation(description: "Mutate finished")
        var result: Result<M, Error>?

        Amplify.API.mutate(request: request) { event in
            switch event {
            case .success(let mResult):
                switch mResult {
                case .success(let object):
                    result = .success(object)
                    mutateFinished.fulfill()
                case .failure(let graphQLError):
                    result = .failure(graphQLError)
                }
            case .failure(let apiError):
                result = .failure(apiError)
            }
        }
        wait(for: [mutateFinished], timeout: TestCommonConstants.networkTimeout)
        guard let mutateResult = result else {
            return .failure(APIError.unknown("Mutation operation timed out", ""))
        }
        return mutateResult
    }

    func queryModel<M: Model>(request: GraphQLRequest<M?>) -> Result<M?, Error> {
        let queryFinished = expectation(description: "Query finished")
        var result: Result<M?, Error>?

        Amplify.API.query(request: request) { event in
            switch event {
            case .success(let mResult):
                switch mResult {
                case .success(let object):
                    result = .success(object)
                    queryFinished.fulfill()
                case .failure(let graphQLError):
                    result = .failure(graphQLError)
                }
            case .failure(let apiError):
                result = .failure(apiError)
            }
        }
        wait(for: [queryFinished], timeout: TestCommonConstants.networkTimeout)
        guard let queryResult = result else {
            return .failure(APIError.unknown("Mutation operation timed out", ""))
        }
        return queryResult
    }
}
