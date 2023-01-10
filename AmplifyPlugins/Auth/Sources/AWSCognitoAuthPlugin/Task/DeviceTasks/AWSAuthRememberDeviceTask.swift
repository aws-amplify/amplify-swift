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

    private let request: AuthRememberDeviceRequest
    private let authStateMachine: AuthStateMachine
    private let environment: AuthEnvironment
    private let taskHelper: AWSAuthTaskHelper

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.rememberDeviceAPI
    }

    init(_ request: AuthRememberDeviceRequest,
         authStateMachine: AuthStateMachine,
         environment: AuthEnvironment) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.environment = environment
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
    }

    func execute() async throws {
        do {
            await taskHelper.didStateMachineConfigured()
            let accessToken = try await taskHelper.getAccessToken()
            let username = try await getCurrentUsername()
            try await rememberDevice(with: accessToken, username: username)
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

    func getCurrentUsername() async throws -> String {
        let authState = await authStateMachine.currentState
        if case .configured(let authenticationState, _) = authState,
           case .signedIn(let signInData) = authenticationState {
           return signInData.username
        }
        throw AuthError.unknown("Unable to get username for the signedIn user")
    }

    private func rememberDevice(with accessToken: String, username: String) async throws {
        let userPoolService = try environment.cognitoUserPoolFactory()
        let deviceMetadata = await DeviceMetadataHelper.getDeviceMetadata(
            for: username,
            environment: environment)
        if case .metadata(let data) = deviceMetadata {
            let input = UpdateDeviceStatusInput(accessToken: accessToken,
                                                deviceKey: data.deviceKey,
                                                deviceRememberedStatus: .remembered)
            _ = try await userPoolService.updateDeviceStatus(input: input)
        } else {
            throw AuthError.unknown("Unable to get device metadata")
        }

    }
}
