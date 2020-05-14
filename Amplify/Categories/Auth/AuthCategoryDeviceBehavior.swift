//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol AuthCategoryDeviceBehavior {

    /// Fetch devices assigned to the current device
    /// - Parameters:
    ///   - options: Parameters specific to plugin behavior.
    ///   - listener: Triggered when the operation completes.
    func fetchDevices(
        options: AuthFetchDevicesOperation.Request.Options?,
        listener: AuthFetchDevicesOperation.EventListener?) -> AuthFetchDevicesOperation

    /// Forget device from the user
    ///
    /// - Parameters:
    ///   - authDevice: Device to be forgotten
    ///   - options: Parameters specific to plugin behavior.
    ///   - listener: Triggered when the operation completes.
    func forget(
        device: AuthDevice?,
        options: AuthForgetDeviceOperation.Request.Options?,
        listener: AuthForgetDeviceOperation.EventListener?) -> AuthForgetDeviceOperation

    /// Make the current user device as remebered
    ///
    /// - Parameters:
    ///   - options: Parameters specific to plugin behavior.
    ///   - listener: Triggered when the operation completes.
    func rememberDevice(
        options: AuthRememberDeviceOperation.Request.Options?,
        listener: AuthRememberDeviceOperation.EventListener?) -> AuthRememberDeviceOperation
}
