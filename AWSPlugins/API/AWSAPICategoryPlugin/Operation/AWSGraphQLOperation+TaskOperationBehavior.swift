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
        self.data.append(data)
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

        // 1. Make sure we can deserialize the response data to json
        let json: JSONValue
        do {
            json = try JSONDecoder().decode(JSONValue.self, from: data)
        } catch {
            dispatch(event: .failed(GraphQLError.operationError("Could not deserialize response data",
                                                                "Service issue",
                                                                error)))
            finish()
            return
        }

        // 2. Make sure the json is an object (meaning it will have "data" and "errors" as key)
        guard case .object(let jsonObject) = json else {
            dispatch(event: .failed(GraphQLError.unknown("Deserialized response data is not an object",
                                                         "Service issue")))
            finish()
            return
        }

        /// 3. Process the errors first
        var errors = [JSONValue]()
        if let errorObject = jsonObject["errors"] {

            guard case .array(let errorArray) = errorObject else {
                dispatch(event: .failed(GraphQLError.unknown("Deserialized response error is not an array",
                                                             "Service issue")))
                finish()
                return
            }

            errors = errorArray
        }

        // 4. Then procss the data
        guard let dataObject = jsonObject["data"] else {

            // 4a. If there is no data, and no errors to return, then fail.
            if errors.isEmpty {
                dispatch(event: .failed(GraphQLError.unknown("Failed to get value at data",
                                                             "Service issue")))
            } else { // 4b. If there is no data, but there is some errors then return those successfully.
                let responseType: R.SerializedObject? = nil
                let response = GraphQLResponse(data: responseType, errors: errors)
                dispatch(event: .completed(response))
            }
            finish()
            return
        }

        // 5. Make sure the data is an object (meaning, the keys are the query names)
        guard case .object(var dataDict) = dataObject else {
            dispatch(event: .failed(GraphQLError.unknown("Failed to case data object to dict",
                                                         "Service issue")))
            finish()
            return
        }

        // 6. Deserialize the data to responseType
        if dataDict.isEmpty { // 6a. nothing to deserialize, so return nil as data and any errors
            let responseType: R.SerializedObject? = nil
            let response = GraphQLResponse(data: responseType, errors: errors)
            dispatch(event: .completed(response))
            finish()
        } else if dataDict.count == 1 { // 6b. Single to deserialize, the value could be a variety of types
            let firstDataValue = dataDict.first!.value

            if case .null = firstDataValue { // 6ba. If the single item has null value, return nil data
                let responseType: R.SerializedObject? = nil
                let response = GraphQLResponse(data: responseType, errors: errors)
                dispatch(event: .completed(response))
                return
            }

            // 6bb. If the single item has object, array, or anything else, just try to deserialize to the responseType
            do {
                let serializedValue = try JSONEncoder().encode(firstDataValue)
                let dataResponse = try JSONDecoder().decode(R.SerializedObject.self, from: serializedValue)
                let response = GraphQLResponse(data: dataResponse, errors: errors)
                dispatch(event: .completed(response))
                finish()
            } catch let decodingError as DecodingError {
                let error = APIErrorMapper.handleDecodingError(error: decodingError)
                dispatch(event: .failed(error))
                finish()
            } catch {
                print("failed to decode \(error)")
                let apiError = GraphQLError.operationError("", "", error)
                dispatch(event: .failed(apiError))
                finish()
            }
        } else { // 6c. There are more than one item to deserialize, ideally we just try to deserialize to responseType
            dispatch(event: .failed(GraphQLError.unknown("more than one query is not yet supported",
                                                         "Could not deserialize")))
            finish()
        }
    }
}



class APIErrorMapper {
    static func handleDecodingError(error: DecodingError) -> GraphQLError {
        switch error {
        case .dataCorrupted(let context):
            let errorMessage = "dataCorrupted"
            let apiError = GraphQLError.operationError(errorMessage, "", error)
            return apiError

        case .typeMismatch(let type, let context):
            let errorMessage = "typeMisMatch type: \(type)"
            let apiError = GraphQLError.operationError(errorMessage, "", error)
            return apiError

        case .valueNotFound(let type, let context):
            let errorMessage = "valueNotFound"
            let apiError = GraphQLError.operationError(errorMessage, "", error)
            return apiError
        case .keyNotFound(let key, let context):
            let errorMessage = "keyNotFound key \(key)"
            let apiError = GraphQLError.operationError(errorMessage, "", error)
            return apiError
        @unknown default:
            print("failed to decode \(error)")
            let apiError = GraphQLError.operationError("", "", error)
            return apiError
        }
    }
}
