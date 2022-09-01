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

class AWSAuthForgetDeviceTask: AuthForgetDeviceTask {
    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior

    private let request: AuthForgetDeviceRequest
    private let authStateMachine: AuthStateMachine
    private let userPoolFactory: CognitoUserPoolFactory
    private let taskHelper: AWSAuthTaskHelper
    
    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.forgetDeviceAPI
    }

    init(_ request: AuthForgetDeviceRequest, authStateMachine: AuthStateMachine, userPoolFactory: @escaping CognitoUserPoolFactory) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.userPoolFactory = userPoolFactory
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
    }

    func execute() async throws {
        do {
            await taskHelper.didStateMachineConfigured()
            let accessToken = try await taskHelper.getAccessToken()
            try await forgetDevice(with: accessToken)
        } catch let error as ForgetDeviceOutputError {
            throw error.authError
        } catch let error as SdkError<ForgetDeviceOutputError> {
            throw error.authError
        } catch let error as AuthError {
            throw error
        } catch let error {
            throw AuthError.unknown("Unable to execute auth task", error)
        }
    }

    private func forgetDevice(with accessToken: String) async throws {
        let userPoolService = try userPoolFactory()
        let input: ForgetDeviceInput
        if let device = request.device {
            input = ForgetDeviceInput(accessToken: accessToken, deviceKey: device.id)
        } else {
            // TODO: pass in current device ID
            input = ForgetDeviceInput(accessToken: accessToken, deviceKey: nil)
        }

        _ = try await userPoolService.forgetDevice(input: input)
    }
}
