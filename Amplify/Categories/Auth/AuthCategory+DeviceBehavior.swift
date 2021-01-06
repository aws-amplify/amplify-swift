//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AuthCategory: AuthCategoryDeviceBehavior {

    @discardableResult
    public func fetchDevices(
        options: AuthFetchDevicesOperation.Request.Options? = nil,
        listener: AuthFetchDevicesOperation.ResultListener?) -> AuthFetchDevicesOperation {
        return plugin.fetchDevices(options: options,
                                   listener: listener)
    }

    @discardableResult
    public func forgetDevice(
        _ device: AuthDevice? = nil,
        options: AuthForgetDeviceOperation.Request.Options? = nil,
        listener: AuthForgetDeviceOperation.ResultListener?) -> AuthForgetDeviceOperation {
        return plugin.forgetDevice(device,
                                   options: options,
                                   listener: listener)
    }

    @discardableResult
    public func rememberDevice(
        options: AuthRememberDeviceOperation.Request.Options? = nil,
        listener: AuthRememberDeviceOperation.ResultListener?) -> AuthRememberDeviceOperation {
        plugin.rememberDevice(options: options, listener: listener)
    }

}
