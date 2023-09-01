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

class VerifyTOTPSetupTask: AuthVerifyTOTPSetupTask, DefaultLogger {

    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior

    private let request: VerifyTOTPSetupRequest
    private let authStateMachine: AuthStateMachine
    private let userPoolFactory: CognitoUserPoolFactory
    private let taskHelper: AWSAuthTaskHelper

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.verifyTOTPSetupAPI
    }

    init(_ request: VerifyTOTPSetupRequest,
         authStateMachine: AuthStateMachine,
         userPoolFactory: @escaping CognitoUserPoolFactory) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.userPoolFactory = userPoolFactory
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
    }

    func execute() async throws {
        do {
            await taskHelper.didStateMachineConfigured()
            let accessToken = try await taskHelper.getAccessToken()
            try await verifyTOTPSetup(
                with: accessToken, userCode: request.code)
        } catch let error as AuthErrorConvertible {
            throw error.authError
        } catch let error as AuthError {
            throw error
        } catch let error {
            throw AuthError.unknown("Unable to execute auth task", error)
        }
    }

    func verifyTOTPSetup(with accessToken: String, userCode: String) async throws  {
        let userPoolService = try userPoolFactory()
        let friendlyDeviceName = (request.options.pluginOptions as? VerifyTOTPSetupOptions)?.friendlyDeviceName
        let input = VerifySoftwareTokenInput(
            accessToken: accessToken,
            friendlyDeviceName: friendlyDeviceName,
            userCode: userCode)
        let result = try await userPoolService.verifySoftwareToken(input: input)

        guard let output = result.status else {
            throw AuthError.service("Verify TOTP Result cannot be retrieved", AmplifyErrorMessages.shouldNotHappenReportBugToAWS())
        }

        switch output {
        case .error:
            throw AuthError.service("Unknown service error occurred",
                                    AmplifyErrorMessages.reportBugToAWS())
        case .success:
            return
        case .sdkUnknown(let error):
            throw AuthError.service(
                error,
                AmplifyErrorMessages.reportBugToAWS())
        }

    }
}
