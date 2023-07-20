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

class AWSAuthFetchDevicesTask: AuthFetchDevicesTask {
    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior

    private let request: AuthFetchDevicesRequest
    private let authStateMachine: AuthStateMachine
    private let userPoolFactory: CognitoUserPoolFactory
    private let taskHelper: AWSAuthTaskHelper

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.fetchDevicesAPI
    }

    init(_ request: AuthFetchDevicesRequest, authStateMachine: AuthStateMachine, userPoolFactory: @escaping CognitoUserPoolFactory) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.userPoolFactory = userPoolFactory
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
    }

    func execute() async throws -> [AuthDevice] {
        do {
            await taskHelper.didStateMachineConfigured()
            let accessToken = try await taskHelper.getAccessToken()
            let devices = try await fetchDevices(with: accessToken)
            return devices
        } catch let error as AuthErrorConvertible {
            throw error.authError
        } catch let error as AuthError {
            throw error
        } catch let error {
            throw AuthError.unknown("Unable to execute auth task", error)
        }
    }

    private func fetchDevices(with accessToken: String) async throws -> [AuthDevice] {
        let userPoolService = try userPoolFactory()
        let input = ListDevicesInput(accessToken: accessToken)
        let result = try await userPoolService.listDevices(input: input)

        guard let devices = result.devices else {
            let authError = AuthError.unknown("Unable to get devices list from response", nil)
            throw authError
        }

        let deviceList = devices.reduce(into: [AuthDevice]()) {
            $0.append($1.toAWSAuthDevice())
        }
        return deviceList
    }
}
