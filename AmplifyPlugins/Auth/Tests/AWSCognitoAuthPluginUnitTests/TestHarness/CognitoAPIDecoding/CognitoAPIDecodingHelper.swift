//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import AWSPluginsCore
import ClientRuntime

@testable import Amplify
@testable import AWSCognitoAuthPlugin
import Foundation

struct CognitoAPIDecodingHelper {

    static func decode(with specification: FeatureSpecification) -> CognitoAPI {

        // Response
        guard let expectedCognitoPrecondition = specification.preConditions.mockedResponses.first(
            where: { response in
                response["type"] == .string("cognito")
            }) else {
            fatalError("Expected Cognito response not found")
        }

        guard case .string(let responseType) = expectedCognitoPrecondition["responseType"] else {
            fatalError("Expected Cognito response not found")
        }

        guard case .string(let apiName) = expectedCognitoPrecondition["apiName"] else {
            fatalError("Expected Cognito response not found")
        }

        guard case .object(let response) = expectedCognitoPrecondition["response"] else {
            fatalError("Expected Cognito response not found")
        }

        let requestData = requestData(for: specification)

        switch apiName {
        case "forgotPassword":
            return forgotPasswordAPI(
                request: requestData,
                response: response,
                responseType: responseType
            )
        default:
            fatalError()
        }
    }

    private static func requestData(for specification: FeatureSpecification) -> Data? {
        var requestData: Data? = nil
        // Request
        if let cognitoResponseValidation = specification.validations.first(where: { validation in
            validation.value(at: "type") == .string("cognito")
        }) {

            guard case .object(let request) = cognitoResponseValidation["request"] else {
                fatalError("Expected Cognito request not found")
            }

            requestData = try! JSONEncoder().encode(request)
        }
        return requestData
    }

    private static func forgotPasswordAPI(
        request: Data?,
        response: [String: JSONValue],
        responseType: String
    ) -> CognitoAPI {
        var forgotPasswordInput: ForgotPasswordInput? = nil

        if let request = request {
            forgotPasswordInput = try! JSONDecoder().decode(ForgotPasswordInput.self, from: request)
        }


        let result: Result<ForgotPasswordOutputResponse, ForgotPasswordOutputError>

        switch responseType {
        case "failure":
            guard case .string(let errorType) = response["errorType"],
                  case .string(let errorMessage) = response["errorType"] else {
                fatalError()
            }

            let forgotPasswordOutputError = try! ForgotPasswordOutputError(
                errorType: errorType,
                //TODO: Figure out a way to pass status code if needed
                httpResponse: .init(body: .empty, statusCode: .ok),
                message: errorMessage)
            result = .failure(forgotPasswordOutputError)
        case "success":
            let responseData = try! JSONEncoder().encode(response)
            let forgotPasswordOutput = try! JSONDecoder().decode(
                ForgotPasswordOutputResponse.self, from: responseData)
            result = .success(forgotPasswordOutput)
        default:
            fatalError("invalid response type")
        }

        return .forgotPassword(
            expectedInput: forgotPasswordInput,
            output: result)
    }

}
