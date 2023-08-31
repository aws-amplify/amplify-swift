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

    static func decode(with specification: FeatureSpecification) async -> [API.APIName: CognitoAPI] {

        var decodedAPIs: [API.APIName: CognitoAPI] = [:]

        for mockedResponse in specification.preConditions.mockedResponses {

            // Response
            guard mockedResponse["type"] == .string("cognitoIdentityProvider") ||
                    mockedResponse["type"] == .string("cognitoIdentity") else {
                continue
            }

            guard case .string(let responseType) = mockedResponse["responseType"] else {
                fatalError("Expected Cognito response not found")
            }

            guard case .string(let apiName) = mockedResponse["apiName"] else {
                fatalError("Expected Cognito response not found")
            }

            guard case .object(let response) = mockedResponse["response"] else {
                fatalError("Expected Cognito response not found")
            }

            let requestData = requestData(
                for: specification,
                with: apiName)

            switch apiName {
            case "forgotPassword":
                decodedAPIs[.forgotPassword] = await .forgotPassword(
                    {
                        await getApiInputAndOutput(
                            request: requestData,
                            response: response,
                            responseType: responseType
                        )
                    }()
                )
            case "signUp":
                decodedAPIs[.signUp] = await .signUp(
                    {
                        await getApiInputAndOutput(
                            request: requestData,
                            response: response,
                            responseType: responseType
                        )
                    }()
                )
            case "deleteUser":
                decodedAPIs[.deleteUser] = await .deleteUser(
                    {
                        await getApiInputAndOutput(
                            request: requestData,
                            response: response,
                            responseType: responseType
                        )
                    }()
                )
            case "respondToAuthChallenge":
                decodedAPIs[.confirmSignIn] = await .respondToAuthChallenge(
                    {
                        await getApiInputAndOutput(
                            request: requestData,
                            response: response,
                            responseType: responseType
                        )
                    }()
                )
            case "confirmDevice":
                decodedAPIs[.confirmDevice] = await .confirmDevice(
                    {
                        await getApiInputAndOutput(
                            request: requestData,
                            response: response,
                            responseType: responseType
                        )
                    }()
                )
            case "initiateAuth":
                decodedAPIs[.initiateAuth] = await .initiateAuth(
                    {
                        await getApiInputAndOutput(
                            request: requestData,
                            response: response,
                            responseType: responseType
                        )
                    }()
                )
            case "revokeToken":
                decodedAPIs[.revokeToken] = await .revokeToken(
                    {
                        await getApiInputAndOutput(
                            request: requestData,
                            response: response,
                            responseType: responseType
                        )
                    }()
                )
            case "getId":
                decodedAPIs[.getId] = await .getId(
                    {
                        await getApiInputAndOutput(
                            request: requestData,
                            response: response,
                            responseType: responseType
                        )
                    }()
                )
            case "getCredentialsForIdentity":
                decodedAPIs[.getCredentialsForIdentity] = await .getCredentialsForIdentity(
                    {
                        await getApiInputAndOutput(
                            request: requestData,
                            response: response,
                            responseType: responseType
                        )
                    }()
                )
            case "globalSignOut":
                decodedAPIs[.globalSignOut] = await .globalSignOut(
                    {
                        await getApiInputAndOutput(
                            request: requestData,
                            response: response,
                            responseType: responseType
                        )
                    }()
                )
            default:
                fatalError()
            }
        }

        return decodedAPIs
    }

    private static func requestData(for specification: FeatureSpecification,
                                    with apiName: String) -> Data? {
        var requestData: Data? = nil
        // Request
        if let cognitoResponseValidation = specification.validations.first(where: { validation in
            validation.value(at: "type") == .string("cognitoIdentityProvider") &&
            validation.value(at: "apiName") == .string(apiName)
        }) {

            guard case .object(let request) = cognitoResponseValidation["request"] else {
                fatalError("Expected Cognito request not found")
            }

            requestData = try! JSONEncoder().encode(request)
        }
        return requestData
    }

    private static func getApiInputAndOutput<
        Input: Decodable,
        Output: Decodable,
        ErrorGenerator: ClientRuntime.HttpResponseErrorBinding
    >(
        request: Data?,
        response: [String: JSONValue],
        responseType: String
    ) async -> CognitoAPIData<Input, Output, ErrorGenerator> {
        var input: Input? = nil

        if let request = request {
            input = try! JSONDecoder().decode(Input.self, from: request)
        }


        let result: Result<Output, Swift.Error>

        switch responseType {
        case "failure":
            guard case .string(let errorType) = response["errorType"],
                  case .string(let errorMessage) = response["errorType"] else {
                fatalError()
            }

            let error = try! await ErrorGenerator.makeError(
                httpResponse: .init(
                    headers: Headers(
                        [
                            "x-amzn-error-message": errorMessage,
                            "X-Amzn-Errortype": "#\(errorType):"]),
                    body: .empty,
                    statusCode: .ok
                ),
                decoder: nil
            )
            result = .failure(error)
        case "success":
            let responseData = try! JSONEncoder().encode(response)
            let output = try! JSONDecoder().decode(
                Output.self, from: responseData)
            result = .success(output)
        default:
            fatalError("invalid response type")
        }
        return CognitoAPIData(expectedInput: input, errorBinding: ErrorGenerator.self, output: result)
    }
}


