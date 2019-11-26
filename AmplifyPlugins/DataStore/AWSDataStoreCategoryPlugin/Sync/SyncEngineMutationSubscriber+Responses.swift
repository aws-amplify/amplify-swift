//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

extension SyncEngineMutationSubscriber {

    static func resolve<R: Decodable>(future: Future<R, DataStoreError>.Promise,
                                      graphQLResponse: GraphQLResponse<R>) {
        switch graphQLResponse {
        case .success(let successResponse):
            future(.success(successResponse))
        case .failure(let error):
            switch error {
                case .error(let graphQLErrors):
                    resolve(future: future, graphQLErrors: graphQLErrors)
                case .partial(let partialResponse, let graphQLErrors):
                    resolve(future: future, partialResponse: partialResponse, graphQLErrors: graphQLErrors)
                case .transformationError(let rawResponse, let transformationError):
                    resolve(future: future, rawResponse: rawResponse, transformationError: transformationError)
                }
            }
    }

    static func resolve<R: Decodable>(future: Future<R, DataStoreError>.Promise,
                                      graphQLErrors: [GraphQLError]) {
        let syncError = DataStoreError.sync(
            "Sync failed with GraphQL errors from service",
            """
            Inspect the errors for more details:
            \(graphQLErrors)
            """
        )
        future(.failure(syncError))
    }

    static func resolve<R: Decodable>(future: Future<R, DataStoreError>.Promise,
                                      partialResponse: R,
                                      graphQLErrors: [GraphQLError]) {
        let syncError = DataStoreError.sync(
            "Sync failed with a partial response from service",
            """
            Partial response:
            \(partialResponse)

            Inspect the errors for more details:
            \(graphQLErrors)
            """
        )
        future(.failure(syncError))
    }

    static func resolve<R: Decodable>(future: Future<R, DataStoreError>.Promise,
                                      rawResponse: RawGraphQLResponse,
                                      transformationError: APIError) {
        let syncError = DataStoreError.sync(
            "Sync failed because it was not able to decode the response into the specified result type",
            """
            Sync failed trying to decode the raw response below into \(String(describing: R.self)). \
            See underlying error for more information. Raw response:
            \(rawResponse)
            """,
            transformationError
        )
        future(.failure(syncError))
    }

}

