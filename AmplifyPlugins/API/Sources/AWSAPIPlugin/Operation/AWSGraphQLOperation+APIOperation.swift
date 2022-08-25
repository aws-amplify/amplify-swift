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
            dispatch(result: .failure(.apiError(error)))
            finish()
            return
        } catch {
            dispatch(result: .failure(APIGraphQLError<R>.unknown("", "", error)))
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
            dispatch(result: .failure(.apiError(error)))
            finish()
            return
        } catch {
            dispatch(result: .failure(APIGraphQLError.unknown("", "", error)))
            finish()
            return
        }

        do {
            let graphQLResponse = try graphQLResponseDecoder.decodeToGraphQLResponse()
            switch graphQLResponse {
            case .success(let responseType):
                dispatch(result: .success(responseType))
            case .failure(let error):
                switch error {
                case .error(let errors):
                    let apiGraphQLError = APIGraphQLError<R>.error(errors)
                    dispatch(result: .failure(apiGraphQLError))
                case .partial(let responseType, let errors):
                    let apiGraphQLError = APIGraphQLError<R>.partial(responseType, errors)
                    dispatch(result: .failure(apiGraphQLError))
                case .transformationError(let response, let apiError):
                    let apiGraphQLError = APIGraphQLError<R>.transformationError(response, apiError)
                    dispatch(result: .failure(apiGraphQLError))
                case .unknown(let error, let recovery, let underlyingError):
                    let apiGraphQLError = APIGraphQLError<R>.unknown(error, recovery, underlyingError)
                    dispatch(result: .failure(apiGraphQLError))
                }
            }
             
            finish()
        } catch let error as APIError {
            dispatch(result: .failure(.apiError(error)))
            finish()
        } catch {
            let apiError = APIError.operationError("failed to process graphqlResponseData", "", error)
            dispatch(result: .failure(.apiError(apiError)))
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
