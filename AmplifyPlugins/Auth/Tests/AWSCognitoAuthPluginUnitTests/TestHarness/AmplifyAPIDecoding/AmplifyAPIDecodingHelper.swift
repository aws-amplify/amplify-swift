//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@testable import AWSCognitoAuthPlugin
import Foundation


struct AmplifyAPIDecodingHelper {

    static func decodeAmplifyAPI(
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
            default:
                fatalError()
            }
        }

    private static func resetPasswordAPI(
        params: JSONValue,
        responseType: String,
        data: Data
    ) -> AmplifyAPI {
        guard case .string(let username) = params["username"] else {
            fatalError("missing username parameter")
        }

        let result: Result<AuthResetPasswordResult, AuthError>

        switch responseType {
        case "failure":
            let authError = try! JSONDecoder().decode(
                AuthError.self, from: data)
            result = .failure(authError)
        case "success":
            let resetPasswordResult = try! JSONDecoder().decode(
                AuthResetPasswordResult.self, from: data)
            result = .success(resetPasswordResult)
        default:
            fatalError("invalid response type")
        }
        return .resetPassword(
            input: .init(username: username,
                         options: .init()),
            expectedOutput: result)
    }
}
