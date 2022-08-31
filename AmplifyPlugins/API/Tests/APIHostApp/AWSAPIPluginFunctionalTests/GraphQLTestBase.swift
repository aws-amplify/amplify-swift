//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import APIHostApp

class GraphQLTestBase: XCTestCase {
    func mutateModel<M: Model>(request: GraphQLRequest<M>) async throws -> M {
        let result = try await Amplify.API.mutate(request: request)
        switch result {
        case .success(let object):
            return object
        case .failure(let graphQLError):
            throw graphQLError
        }
    }

    func queryModel<M: Model>(request: GraphQLRequest<M?>) async throws -> M? {
        let result = try await Amplify.API.query(request: request)
        switch result {
        case .success(let object):
            return object
        case .failure(let graphQLError):
            throw graphQLError
        }
    }
}
