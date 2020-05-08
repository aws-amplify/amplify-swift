//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AWSAuthPlugin {

    public func fetchDevices(
        options: AuthFetchDevicesOperation.Request.Options? = nil,
        listener: AuthFetchDevicesOperation.EventListener?) -> AuthFetchDevicesOperation {

        let options = options ?? AuthFetchDevicesRequest.Options()
        let request = AuthFetchDevicesRequest(options: options)
        let fetchDeviceOperation = AWSAuthFetchDevicesOperation(request,
                                                                deviceService: deviceService,
                                                                listener: listener)
        queue.addOperation(fetchDeviceOperation)
        return fetchDeviceOperation
    }

    public func forget(
        device: AuthDevice? = nil,
        options: AuthForgetDeviceOperation.Request.Options? = nil,
        listener: AuthForgetDeviceOperation.EventListener?) -> AuthForgetDeviceOperation {

        let options = options ?? AuthForgetDeviceRequest.Options()
        let request = AuthForgetDeviceRequest(device: device, options: options)
        let fetchDeviceOperation = AWSAuthForgetDeviceOperation(request,
                                                                deviceService: deviceService,
                                                                listener: listener)
        queue.addOperation(fetchDeviceOperation)
        return fetchDeviceOperation
    }

    public func rememberDevice(
        options: AuthRememberDeviceOperation.Request.Options? = nil,
        listener: AuthRememberDeviceOperation.EventListener?) -> AuthRememberDeviceOperation {
        let options = options ?? AuthRememberDeviceRequest.Options()
        let request = AuthRememberDeviceRequest(options: options)
        let fetchDeviceOperation = AWSAuthRememberDeviceOperation(request,
                                                                  deviceService: deviceService,
                                                                  listener: listener)
        queue.addOperation(fetchDeviceOperation)
        return fetchDeviceOperation
    }
}
