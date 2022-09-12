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

    private let request: AuthForgetDeviceRequest
    private let authStateMachine: AuthStateMachine
    private let environment: AuthEnvironment
    private let taskHelper: AWSAuthTaskHelper

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.forgetDeviceAPI
    }

    init(_ request: AuthForgetDeviceRequest,
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
            try await forgetDevice(with: accessToken, username: username)
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

    func getCurrentUsername() async throws -> String {
        let authState = await authStateMachine.currentState
        if case .configured(let authenticationState, _) = authState,
           case .signedIn(let signInData) = authenticationState {
           return signInData.userName
        }
        throw AuthError.unknown("Unable to get username for the signedIn user")
    }

    private func forgetDevice(with accessToken: String, username: String) async throws {
        let userPoolService = try environment.cognitoUserPoolFactory()
        guard let device = request.device else {
            let deviceMetadata = await DeviceMetadataHelper.getDeviceMetadata(
                for: environment,
                with: username)
            if case .metadata(let data) = deviceMetadata {
                let input = ForgetDeviceInput(accessToken: accessToken, deviceKey: data.deviceKey)
                _ = try await userPoolService.forgetDevice(input: input)
            } else {
                throw AuthError.unknown("Unable to get device metadata")
            }
            return
        }
        let input = ForgetDeviceInput(accessToken: accessToken, deviceKey: device.id)
        _ = try await userPoolService.forgetDevice(input: input)
    }
}
