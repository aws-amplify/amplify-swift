//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol AuthCategoryDeviceBehavior: AnyObject {

    /// Fetch devices assigned to the current device
    /// - Parameters:
    ///   - options: Parameters specific to plugin behavior.
    ///   - listener: Triggered when the operation completes.
    @discardableResult
    func fetchDevices(
        options: AuthFetchDevicesOperation.Request.Options?,
        listener: AuthFetchDevicesOperation.ResultListener?) -> AuthFetchDevicesOperation

    /// Forget device from the user
    ///
    /// - Parameters:
    ///   - authDevice: Device to be forgotten
    ///   - options: Parameters specific to plugin behavior.
    ///   - listener: Triggered when the operation completes.
    @discardableResult
    func forgetDevice(
        _ device: AuthDevice?,
        options: AuthForgetDeviceOperation.Request.Options?,
        listener: AuthForgetDeviceOperation.ResultListener?) -> AuthForgetDeviceOperation

    /// Make the current user device as remebered
    ///
    /// - Parameters:
    ///   - options: Parameters specific to plugin behavior.
    ///   - listener: Triggered when the operation completes.
    @discardableResult
    func rememberDevice(
        options: AuthRememberDeviceOperation.Request.Options?,
        listener: AuthRememberDeviceOperation.ResultListener?) -> AuthRememberDeviceOperation
}
