//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AWSCognitoAuthPlugin {

    public func fetchDevices(
        options: AuthFetchDevicesOperation.Request.Options? = nil,
        listener: AuthFetchDevicesOperation.ResultListener?) -> AuthFetchDevicesOperation {

        let options = options ?? AuthFetchDevicesRequest.Options()
        let request = AuthFetchDevicesRequest(options: options)
        let fetchDeviceOperation = AWSAuthFetchDevicesOperation(request,
                                                                deviceService: deviceService,
                                                                resultListener: listener)
        queue.addOperation(fetchDeviceOperation)
        return fetchDeviceOperation
    }

    public func forgetDevice(
        _ device: AuthDevice? = nil,
        options: AuthForgetDeviceOperation.Request.Options? = nil,
        listener: AuthForgetDeviceOperation.ResultListener?) -> AuthForgetDeviceOperation {

        let options = options ?? AuthForgetDeviceRequest.Options()
        let request = AuthForgetDeviceRequest(device: device, options: options)
        let fetchDeviceOperation = AWSAuthForgetDeviceOperation(request,
                                                                deviceService: deviceService,
                                                                resultListener: listener)
        queue.addOperation(fetchDeviceOperation)
        return fetchDeviceOperation
    }

    public func rememberDevice(
        options: AuthRememberDeviceOperation.Request.Options? = nil,
        listener: AuthRememberDeviceOperation.ResultListener?) -> AuthRememberDeviceOperation {
        let options = options ?? AuthRememberDeviceRequest.Options()
        let request = AuthRememberDeviceRequest(options: options)
        let fetchDeviceOperation = AWSAuthRememberDeviceOperation(request,
                                                                  deviceService: deviceService,
                                                                  resultListener: listener)
        queue.addOperation(fetchDeviceOperation)
        return fetchDeviceOperation
    }
}
