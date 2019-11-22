//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension AWSGraphQLOperation: APIOperation {
    func getOperationId() -> UUID {
        return id
    }

    func cancelOperation() {
        cancel()
    }

    func updateProgress(_ data: Data, response: URLResponse?) {
        if isCancelled || isFinished {
            finish()
            return
        }

        let apiOperationResponse = APIOperationResponse(error: nil, response: response)
        do {
            try apiOperationResponse.validate()
        } catch let error as APIError {
            dispatch(event: .failed(error))
            finish()
            return
        } catch {
            dispatch(event: .failed(APIError.unknown("", "", error)))
            finish()
            return
        }

        graphQLResponseData.append(data)
    }

    func complete(with error: Error?, response: URLResponse?) {
        if isCancelled || isFinished {
            finish()
            return
        }

        let apiOperationResponse = APIOperationResponse(error: error, response: response)
        do {
            try apiOperationResponse.validate()
        } catch let error as APIError {
            dispatch(event: .failed(error))
            finish()
            return
        } catch {
            dispatch(event: .failed(APIError.unknown("", "", error)))
            finish()
            return
        }

        do {
            let graphQLServiceResponse = try GraphQLResponseDecoder.deserialize(graphQLResponse: graphQLResponseData)

            let graphQLResponse = try GraphQLResponseDecoder.decode(graphQLServiceResponse: graphQLServiceResponse,
                                                                    responseType: request.responseType,
                                                                    decodePath: request.decodePath,
                                                                    rawGraphQLResponse: graphQLResponseData)

            dispatch(event: .completed(graphQLResponse))
            finish()
        } catch let error as APIError {
            dispatch(event: .failed(error))
            finish()
        } catch {
            let apiError = APIError.operationError("failed to process graphqlResponseData", "", error)
            dispatch(event: .failed(apiError))
            finish()
        }
    }
}

class APIErrorHelper {

    static func getDefaultError(_ error: NSError) -> APIError {
        let errorMessage = """
                           Domain: [\(error.domain)
                           Code: [\(error.code)
                           LocalizedDescription: [\(error.localizedDescription)
                           LocalizedFailureReason: [\(error.localizedFailureReason ?? "")
                           LocalizedRecoverySuggestion: [\(error.localizedRecoverySuggestion ?? "")
                           """

        return APIError.unknown(errorMessage, "", error)
    }
}
