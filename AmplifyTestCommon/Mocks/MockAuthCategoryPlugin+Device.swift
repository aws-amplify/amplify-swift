//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension MockAuthCategoryPlugin {

    public func fetchDevices(
        options: AuthFetchDevicesOperation.Request.Options? = nil,
        listener: AuthFetchDevicesOperation.ResultListener?
    ) -> AuthFetchDevicesOperation {
        notify()
        if let responder = responders.fetchDevices {
            let result = responder(options)
            listener?(result)
        }
        let request = AuthFetchDevicesOperation.Request(
            options: options ?? AuthFetchDevicesOperation.Request.Options()
        )
        return MockAuthFetchDevicesOperation(request: request)
    }

    public func forgetDevice(
        _ device: AuthDevice? = nil,
        options: AuthForgetDeviceOperation.Request.Options? = nil,
        listener: AuthForgetDeviceOperation.ResultListener?
    ) -> AuthForgetDeviceOperation {
        notify()
        if let responder = responders.forgetDevice {
            let result = responder(device, options)
            listener?(result)
        }
        let request = AuthForgetDeviceOperation.Request(
            device: device,
            options: options ?? AuthForgetDeviceOperation.Request.Options()
        )
        return MockAuthForgetDeviceOperation(request: request)
    }

    public func rememberDevice(
        options: AuthRememberDeviceOperation.Request.Options? = nil,
        listener: AuthRememberDeviceOperation.ResultListener?
    ) -> AuthRememberDeviceOperation {
        notify()
        if let responder = responders.rememberDevice {
            let result = responder(options)
            listener?(result)
        }
        let request = AuthRememberDeviceOperation.Request(
            options: options ?? AuthRememberDeviceOperation.Request.Options()
        )
        return MockAuthRememberDeviceOperation(request: request)
    }

}
