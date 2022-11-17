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
                response["type"] == .string("cognitoIdentityProvider")
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
        case "signUp":
            return signUpApi(
                request: requestData,
                response: response,
                responseType: responseType
            )
        case "deleteUser":
            return deleteUserApi(
                request: requestData,
                response: response,
                responseType: responseType
            )
        case "respondToAuthChallenge":
            return confirmSignInApi(
                request: requestData,
                response: response,
                responseType: responseType)
        default:
            fatalError()
        }
    }

    private static func requestData(for specification: FeatureSpecification) -> Data? {
        var requestData: Data? = nil
        // Request
        if let cognitoResponseValidation = specification.validations.first(where: { validation in
            validation.value(at: "type") == .string("cognitoIdentityProvider")
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

    private static func signUpApi(
        request: Data?,
        response: [String: JSONValue],
        responseType: String
    ) -> CognitoAPI {
        var signUpInput: SignUpInput? = nil

        if let request = request {
            signUpInput = try! JSONDecoder().decode(SignUpInput.self, from: request)
        }

        let result: Result<SignUpOutputResponse, SignUpOutputError>

        switch responseType {
        case "failure":
            guard case .string(let errorType) = response["errorType"],
                  case .string(let errorMessage) = response["errorType"] else {
                fatalError()
            }

            let signUpOutputError = try! SignUpOutputError(
                errorType: errorType,
                //TODO: Figure out a way to pass status code if needed
                httpResponse: .init(body: .empty, statusCode: .ok),
                message: errorMessage)
            result = .failure(signUpOutputError)
        case "success":
            let responseData = try! JSONEncoder().encode(response)
            let signUpOutput = try! JSONDecoder().decode(
                SignUpOutputResponse.self, from: responseData)
            result = .success(signUpOutput)
        default:
            fatalError("invalid response type")
        }

        return .signUp(
            expectedInput: signUpInput,
            output: result)
    }

    private static func deleteUserApi(
        request: Data?,
        response: [String: JSONValue],
        responseType: String
    ) -> CognitoAPI {
        var input: DeleteUserInput? = nil

        if let request = request {
            input = try! JSONDecoder().decode(DeleteUserInput.self, from: request)
        }

        let result: Result<DeleteUserOutputResponse, DeleteUserOutputError>

        switch responseType {
        case "failure":
            guard case .string(let errorType) = response["errorType"],
                  case .string(let errorMessage) = response["errorType"] else {
                fatalError()
            }

            let error = try! DeleteUserOutputError(
                errorType: errorType,
                //TODO: Figure out a way to pass status code if needed
                httpResponse: .init(body: .empty, statusCode: .ok),
                message: errorMessage)
            result = .failure(error)
        case "success":
            let responseData = try! JSONEncoder().encode(response)
            let response = try! JSONDecoder().decode(
                DeleteUserOutputResponse.self, from: responseData)
            result = .success(response)
        default:
            fatalError("invalid response type")
        }

        return .deleteUser(
            expectedInput: input,
            output: result)
    }

                private static func confirmSignInApi(
                    request: Data?,
                    response: [String: JSONValue],
                    responseType: String
                ) -> CognitoAPI {
                    var input: RespondToAuthChallengeInput? = nil

                    if let request = request {
                        input = try! JSONDecoder().decode(RespondToAuthChallengeInput.self, from: request)
                    }

                    let result: Result<RespondToAuthChallengeOutputResponse, RespondToAuthChallengeOutputError>

                    switch responseType {
                    case "failure":
                        guard case .string(let errorType) = response["errorType"],
                              case .string(let errorMessage) = response["errorType"] else {
                            fatalError()
                        }

                        let error = try! RespondToAuthChallengeOutputError(
                            errorType: errorType,
                            //TODO: Figure out a way to pass status code if needed
                            httpResponse: .init(body: .empty, statusCode: .ok),
                            message: errorMessage)
                        result = .failure(error)
                    case "success":
                        let responseData = try! JSONEncoder().encode(response)
                        let output = try! JSONDecoder().decode(
                            RespondToAuthChallengeOutputResponse.self, from: responseData)
                        result = .success(output)
                    default:
                        fatalError("invalid response type")
                    }

                    return .confirmSignIn(
                        expectedInput: input,
                        output: result)
                }

}
