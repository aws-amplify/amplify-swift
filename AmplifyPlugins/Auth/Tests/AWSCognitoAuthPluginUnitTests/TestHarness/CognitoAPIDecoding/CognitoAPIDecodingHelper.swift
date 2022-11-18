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

    static func decode(with specification: FeatureSpecification) -> [API.APIName: CognitoAPI] {

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
                decodedAPIs[.forgotPassword] = forgotPasswordAPI(
                    request: requestData,
                    response: response,
                    responseType: responseType
                )
            case "signUp":
                decodedAPIs[.signUp] = signUpApi(
                    request: requestData,
                    response: response,
                    responseType: responseType
                )
            case "deleteUser":
                decodedAPIs[.deleteUser] = deleteUserApi(
                    request: requestData,
                    response: response,
                    responseType: responseType
                )
            case "respondToAuthChallenge":
                decodedAPIs[.confirmSignIn] = confirmSignInApi(
                    request: requestData,
                    response: response,
                    responseType: responseType)
            case "getId":
                decodedAPIs[.getId] = getIdApi(
                    request: requestData,
                    response: response,
                    responseType: responseType)
            case "getCredentialsForIdentity":
                decodedAPIs[.getCredentialsForIdentity] = getCredentialsForIdentityApi(
                    request: requestData,
                    response: response,
                    responseType: responseType)
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

    private static func getIdApi(
        request: Data?,
        response: [String: JSONValue],
        responseType: String
    ) -> CognitoAPI {
        var input: GetIdInput? = nil

        if let request = request {
            input = try! JSONDecoder().decode(GetIdInput.self, from: request)
        }

        let result: Result<GetIdOutputResponse, GetIdOutputError>

        switch responseType {
        case "failure":
            guard case .string(let errorType) = response["errorType"],
                  case .string(let errorMessage) = response["errorType"] else {
                fatalError()
            }

            let error = try! GetIdOutputError(
                errorType: errorType,
                //TODO: Figure out a way to pass status code if needed
                httpResponse: .init(body: .empty, statusCode: .ok),
                message: errorMessage)
            result = .failure(error)
        case "success":
            let responseData = try! JSONEncoder().encode(response)
            let output = try! JSONDecoder().decode(
                GetIdOutputResponse.self, from: responseData)
            result = .success(output)
        default:
            fatalError("invalid response type")
        }

        return .getId(
            expectedInput: input,
            output: result)
    }

    private static func getCredentialsForIdentityApi(
        request: Data?,
        response: [String: JSONValue],
        responseType: String
    ) -> CognitoAPI {
        var input: GetCredentialsForIdentityInput? = nil

        if let request = request {
            input = try! JSONDecoder().decode(GetCredentialsForIdentityInput.self, from: request)
        }

        let result: Result<GetCredentialsForIdentityOutputResponse, GetCredentialsForIdentityOutputError>

        switch responseType {
        case "failure":
            guard case .string(let errorType) = response["errorType"],
                  case .string(let errorMessage) = response["errorType"] else {
                fatalError()
            }

            let error = try! GetCredentialsForIdentityOutputError(
                errorType: errorType,
                //TODO: Figure out a way to pass status code if needed
                httpResponse: .init(body: .empty, statusCode: .ok),
                message: errorMessage)
            result = .failure(error)
        case "success":
            let responseData = try! JSONEncoder().encode(response)
            let output = try! JSONDecoder().decode(
                GetCredentialsForIdentityOutputResponse.self, from: responseData)
            result = .success(output)
        default:
            fatalError("invalid response type")
        }

        return .getCredentialsForIdentity(
            expectedInput: input,
            output: result)
    }

}
