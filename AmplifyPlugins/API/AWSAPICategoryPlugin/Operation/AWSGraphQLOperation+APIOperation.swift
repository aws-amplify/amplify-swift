//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
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
            dispatch(result: .failure(error))
            finish()
            return
        } catch {
            dispatch(result: .failure(APIError.unknown("", "", error)))
            finish()
            return
        }

        graphQLResponseDecoder.appendResponse(data)
    }

    func complete(with error: Error?, response: URLResponse?) {
        if isCancelled || isFinished {
            finish()
            return
        }

        mapper.removePair(for: self)

        let apiOperationResponse = APIOperationResponse(error: error, response: response)
        do {
            try apiOperationResponse.validate()
        } catch let error as APIError {
            dispatch(result: .failure(error))
            finish()
            return
        } catch {
            dispatch(result: .failure(APIError.unknown("", "", error)))
            finish()
            return
        }

        do {
            let graphQLResponse = try graphQLResponseDecoder.decodeToGraphQLResponse()
            dispatch(result: .success(graphQLResponse))
            finish()
        } catch let error as APIError {
            dispatch(result: .failure(error))
            finish()
        } catch {
            let apiError = APIError.operationError("failed to process graphqlResponseData", "", error)
            dispatch(result: .failure(apiError))
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
