//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension AWSGraphQLOperation: TaskOperationBehavior {
    func getOperationId() -> UUID {
        return id
    }

    func cancelOperation() {
        cancel()
    }

    func updateProgress(_ data: Data) {
        graphQLResponseData.append(data)
    }

    func complete(with error: Error?) {
        if let error = error {
            let apiError = GraphQLError.operationError(
                "The operation for this request failed.",
                """
                The operation for the request shown below failed with the following message: \
                \(error.localizedDescription).

                Inspect this error's `.error` property for more information.

                Request:
                \(request)
                """,
                error)

            dispatch(event: .failed(apiError))
            finish()
            return
        }

        do {
            let graphQLServiceResponse = try GraphQLResponseDecoder.deserialize(graphQLResponse: graphQLResponseData)

            let graphQLResponse = try GraphQLResponseDecoder.decode(graphQLServiceResponse: graphQLServiceResponse,
                                                                    responseType: responseType)

            dispatch(event: .completed(graphQLResponse))
            finish()
        } catch let error as GraphQLError {
            dispatch(event: .failed(error))
            finish()
        } catch {
            let graphQLError = GraphQLError.operationError("failed to process graphqlResponseData", "", error)
            dispatch(event: .failed(graphQLError))
            finish()
        }
    }
}
