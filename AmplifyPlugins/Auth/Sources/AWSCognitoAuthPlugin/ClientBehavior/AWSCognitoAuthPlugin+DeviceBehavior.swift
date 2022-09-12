//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension AWSCognitoAuthPlugin: AuthCategoryDeviceBehavior {

    public func fetchDevices(options: AuthFetchDevicesRequest.Options? = nil) async throws
    -> [AuthDevice] {
        let options = options ?? AuthFetchDevicesRequest.Options()
        let request = AuthFetchDevicesRequest(options: options)
        let task = AWSAuthFetchDevicesTask(request,
                                           authStateMachine: authStateMachine,
                                           userPoolFactory: authEnvironment.cognitoUserPoolFactory)
        return try await task.value
    }

    public func forgetDevice(_ device: AuthDevice? = nil,
                              options: AuthForgetDeviceRequest.Options? = nil) async throws {
        let options = options ?? AuthForgetDeviceRequest.Options()
        let request = AuthForgetDeviceRequest(device: device, options: options)
        let task = AWSAuthForgetDeviceTask(request,
                                           authStateMachine: authStateMachine,
                                           environment: authEnvironment)
        return try await task.value
        }

    public func rememberDevice( options: AuthRememberDeviceRequest.Options? = nil) async throws {
        let options = options ?? AuthRememberDeviceRequest.Options()
        let request = AuthRememberDeviceRequest(options: options)
        let task = AWSAuthRememberDeviceTask(request,
                                             authStateMachine: authStateMachine,
                                             environment: authEnvironment)
        return try await task.value
    }
}
