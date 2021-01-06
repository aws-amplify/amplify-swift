//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// No-listener versions of the public APIs, to clean call sites that use Combine
// publishers to get results

public extension AuthCategoryDeviceBehavior {

    /// Fetch devices assigned to the current device
    /// - Parameters:
    ///   - options: Parameters specific to plugin behavior.
    func fetchDevices(
        options: AuthFetchDevicesOperation.Request.Options? = nil
    ) -> AuthFetchDevicesOperation {
        fetchDevices(options: options, listener: nil)
    }

    /// Forget device from the user
    ///
    /// - Parameters:
    ///   - authDevice: Device to be forgotten
    ///   - options: Parameters specific to plugin behavior.
    func forgetDevice(
        _ device: AuthDevice? = nil,
        options: AuthForgetDeviceOperation.Request.Options? = nil
    ) -> AuthForgetDeviceOperation {
        forgetDevice(device, options: options, listener: nil)
    }

    /// Make the current user device as remebered
    ///
    /// - Parameters:
    ///   - options: Parameters specific to plugin behavior.
    func rememberDevice(
        options: AuthRememberDeviceOperation.Request.Options? = nil
    ) -> AuthRememberDeviceOperation {
        rememberDevice(options: options, listener: nil)
    }
}
