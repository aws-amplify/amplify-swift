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

class AWSAuthRememberDeviceTask: AuthRememberDeviceTask {
    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior

    private let request: AuthRememberDeviceRequest
    private let authStateMachine: AuthStateMachine
    private let userPoolFactory: CognitoUserPoolFactory
    private var stateMachineToken: AuthStateMachineToken?
    private let taskHelper: AWSAuthTaskHelper
    
    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.rememberDeviceAPI
    }

    init(_ request: AuthRememberDeviceRequest, authStateMachine: AuthStateMachine, userPoolFactory: @escaping CognitoUserPoolFactory) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.userPoolFactory = userPoolFactory
        self.taskHelper = AWSAuthTaskHelper(stateMachineToken: self.stateMachineToken, authStateMachine: authStateMachine)
    }

    func execute() async throws {
        do {
            await taskHelper.didStateMachineConfigured()
            let accessToken = try await taskHelper.getAccessToken()
            try await rememberDevice(with: accessToken)
        } catch let error as UpdateDeviceStatusOutputError {
            throw error.authError
        } catch let error as SdkError<UpdateDeviceStatusOutputError> {
            throw error.authError
        } catch let error as AuthError {
            throw error
        } catch let error {
            throw AuthError.unknown("Unable to execute auth task", error)
        }
    }

    private func rememberDevice(with accessToken: String) async throws {
        let userPoolService = try userPoolFactory()

        // TODO: Pass in device key when implemented
        let input = UpdateDeviceStatusInput(accessToken: accessToken,
                                            deviceKey: nil,
                                            deviceRememberedStatus: .remembered)
        _ = try await userPoolService.updateDeviceStatus(input: input)
    }
}
