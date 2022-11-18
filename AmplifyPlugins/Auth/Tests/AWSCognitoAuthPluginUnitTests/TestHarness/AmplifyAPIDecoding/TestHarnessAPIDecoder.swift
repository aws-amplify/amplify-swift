//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@testable import AWSCognitoAuthPlugin
import Foundation


struct TestHarnessAPIDecoder {

    static func decode(
        specification: FeatureSpecification) -> AmplifyAPI {

            guard let expectedAmplifyResponseValidation = specification.validations.first(where: { validation in
                validation.value(at: "type") == .string("amplify")
            }) else {
                fatalError("Expected Amplify response not found")
            }

            guard case .string(let responseType) = expectedAmplifyResponseValidation["responseType"] else {
                fatalError("Expected Amplify response type not found")
            }

            guard case .object(let response) = expectedAmplifyResponseValidation["response"] else {
                fatalError("Expected Amplify response not found")
            }

            let data = try! JSONEncoder().encode(response)

            switch specification.api.name {
            case .resetPassword:
                return resetPasswordAPI(
                    params: specification.api.params,
                    responseType: responseType,
                    data: data
                )
            case .signIn:
                return signInAPI(
                    params: specification.api.params,
                    responseType: responseType,
                    data: data)
            case .signUp:
                return signUpAPI(
                    params: specification.api.params,
                    responseType: responseType,
                    data: data)
            case .deleteUser:
                return deleteUserAPI(
                    params: specification.api.params,
                    responseType: responseType,
                    data: data)
            case .confirmSignIn:
                return confirmSignInAPI(
                    params: specification.api.params,
                    responseType: responseType,
                    data: data)
            case .fetchAuthSession:
                return fetchAuthSession(
                    params: specification.api.params,
                    responseType: responseType,
                    data: data)
            case .signOut:
                return signOutApi(
                    options: specification.api.options,
                    responseType: responseType,
                    data: data)
            default:
                fatalError()
            }
        }

    private static func signInAPI(
        params: JSONValue,
        responseType: String,
        data: Data
    ) -> AmplifyAPI {
        guard case .string(let username) = params["username"] else {
            fatalError("missing username parameter")
        }
        var inputPassword: String?
        if case .string(let password) = params["password"] {
            inputPassword = password
        }
        return .signIn(
            input: .init(
                username: username,
                password: inputPassword, options: .init()),
            expectedOutput: generateResult(responseType: responseType, data: data))
    }

    private static func signUpAPI(
        params: JSONValue,
        responseType: String,
        data: Data
    ) -> AmplifyAPI {
        guard case .string(let username) = params["username"] else {
            fatalError("missing username parameter")
        }
        var inputPassword: String?
        if case .string(let password) = params["password"] {
            inputPassword = password
        }
        return .signUp(
            input: .init(
                username: username,
                password: inputPassword, options: .init()),
            expectedOutput: generateResult(responseType: responseType, data: data))
    }

    private static func resetPasswordAPI(
        params: JSONValue,
        responseType: String,
        data: Data
    ) -> AmplifyAPI {
        guard case .string(let username) = params["username"] else {
            fatalError("missing username parameter")
        }
        return .resetPassword(
            input: .init(username: username,
                         options: .init()),
            expectedOutput: generateResult(responseType: responseType, data: data))
    }

    private static func confirmSignInAPI(
        params: JSONValue,
        responseType: String,
        data: Data
    ) -> AmplifyAPI {
        guard case .string(let challengeResponse) = params["challengeResponse"] else {
            fatalError("missing username parameter")
        }
        return .confirmSignIn(
            input: .init(challengeResponse: challengeResponse, options: .init()),
            expectedOutput: generateResult(responseType: responseType, data: data))
    }

    private static func fetchAuthSession(
        params: JSONValue,
        responseType: String,
        data: Data
    ) -> AmplifyAPI {

        let result: Result<AWSAuthCognitoSession, AuthError> = generateResult(
            responseType: responseType, data: data)

        return .fetchAuthSession(
            input: .init(options: .init()),
            expectedOutput: result)
    }

    private static func signOutApi(
        options: JSONValue,
        responseType: String,
        data: Data
    ) -> AmplifyAPI {

        var globalSignOut = false
        if case .boolean(let globalSignOutVal) = options["globalSignOut"] {
            globalSignOut = globalSignOutVal
        }

        let result: Result<AWSCognitoSignOutResult, AuthError> = generateResult(
            responseType: responseType, data: data)

        return .signOut(
            input: .init(options: .init(globalSignOut: globalSignOut)),
            expectedOutput: result)
    }

    private static func deleteUserAPI(
        params: JSONValue,
        responseType: String,
        data: Data
    ) -> AmplifyAPI {

        let result: Result<Void, AuthError>

        switch responseType {
        case "failure":
            let authError = try! JSONDecoder().decode(
                AuthError.self, from: data)
            result = .failure(authError)
        case "success":
            result = .success(())
        default:
            fatalError("invalid response type")
        }
        return .deleteUser(
            input: (),
            expectedOutput: result)
    }

    private static func generateResult<Output: Decodable>(
        responseType: String, data: Data) -> Result<Output, AuthError> {

        let result: Result<Output, AuthError>

        switch responseType {
        case "failure":
            let authError = try! JSONDecoder().decode(
                AuthError.self, from: data)
            result = .failure(authError)
        case "success":
            let output = try! JSONDecoder().decode(
                Output.self, from: data)
            result = .success(output)
        default:
            fatalError("invalid response type")
        }
        return result
    }
}
