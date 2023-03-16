//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore
import ClientRuntime
import AWSCognitoIdentityProvider

class AWSAuthVerifySoftwareTokenTask: AuthVerifySoftwareTokenTask, DefaultLogger {

    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior

    private let request: AuthVerifySoftwareTokenRequest
    private let authStateMachine: AuthStateMachine
    private let userPoolFactory: CognitoUserPoolFactory
    private let taskHelper: AWSAuthTaskHelper

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.associateSoftwareTokenAPI
    }

    init(_ request: AuthVerifySoftwareTokenRequest,
         authStateMachine: AuthStateMachine,
         userPoolFactory: @escaping CognitoUserPoolFactory) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.userPoolFactory = userPoolFactory
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
    }

    func execute() async throws -> AuthAssociateSoftwareTokenResult {
        do {
            await taskHelper.didStateMachineConfigured()
            let accessToken = try await taskHelper.getAccessToken()
            return try await verifySoftwareToken(
                with: accessToken, userCode: request.verificationCode)
        } catch let error as AuthErrorConvertible {
            throw error.authError
        } catch let error as AuthError {
            throw error
        } catch let error {
            throw AuthError.unknown("Unable to execute auth task", error)
        }
    }

    func verifySoftwareToken(with accessToken: String, userCode: String) async throws -> AuthAssociateSoftwareTokenResult {
        let userPoolService = try userPoolFactory()
        let input = VerifySoftwareTokenInput(
            accessToken: accessToken,
            friendlyDeviceName: "",
            session: nil,
            userCode: userCode)
        let result = try await userPoolService.verifySoftwareToken(input: input)

        guard let output = result.status else {
            throw AuthError.service("Result cannot be retrieved", "")
        }

        switch output {
        case .error:
            throw AuthError.service("Unknown error", "")
        case .success:
            return .init(nextStep: .done)
        case .sdkUnknown(let error):
            throw AuthError.service("Unknown error", error)
        }


    }
}
