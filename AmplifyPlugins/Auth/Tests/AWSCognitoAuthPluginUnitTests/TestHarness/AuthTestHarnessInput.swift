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

struct AuthTestHarnessInput {
    let initialAuthState: AuthState
    let expectedAuthState: AuthState?
    let amplifyAPI: AmplifyAPI
    let cognitoAPI: CognitoAPI
}

extension AuthTestHarnessInput {

    static func createInput(from specification: FeatureSpecification) -> AuthTestHarnessInput {

        return AuthTestHarnessInput(
            initialAuthState: specification.preConditions.initialAuthState,
            expectedAuthState: getExpectedAuthState(from: specification),
            amplifyAPI: getAmplifyAPIUnderTest(from: specification),
            cognitoAPI: getCognitoAPI(from: specification)
        )
    }

    private static func getAmplifyAPIUnderTest(from specification: FeatureSpecification) -> AmplifyAPI {
        return TestHarnessAPIDecoder.decode(
            specification: specification)
    }

    private static func getCognitoAPI(
        from specification: FeatureSpecification) -> CognitoAPI {
            return CognitoAPIDecodingHelper.decode(with: specification)
    }

    private static func getExpectedAuthState(from specification: FeatureSpecification) -> AuthState? {
        guard let expectedAuthStateValidation = specification.validations.first(where: { validation in
            validation.value(at: "type") == .string("state")
        }) else {
            return nil
        }
        guard case .string(let expectedAuthStateFileName) = expectedAuthStateValidation.value(at: "expectedState") else {
            fatalError("State validation not found")
        }
        return AuthState.initialize(fileName: expectedAuthStateFileName)
    }
}

enum AmplifyAPI {
    case resetPassword(
        input: AuthResetPasswordRequest,
        expectedOutput: Result<AuthResetPasswordResult, AuthError>?)
}

enum CognitoAPI {
    case forgotPassword(
        expectedInput: ForgotPasswordInput?,
        output: Result<ForgotPasswordOutputResponse, ForgotPasswordOutputError>)
}
