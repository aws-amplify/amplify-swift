//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

public extension AuthCategoryDeviceBehavior {

    /// Fetch devices assigned to the current user
    ///
    /// - Parameters:
    ///   - options: Parameters specific to plugin behavior
    /// - Returns: An AuthPublisher with the results of the operation
    func fetchDevices(
        options: AuthFetchDevicesOperation.Request.Options? = nil
    ) -> AuthPublisher<[AuthDevice]> {
        Future { promise in
            _ = self.fetchDevices(options: options) { promise($0) }
        }.eraseToAnyPublisher()
    }

    /// Forget a device from the user
    ///
    /// - Parameters:
    ///   - authDevice: Device to be forgotten. Defaults to the current device.
    ///   - options: Parameters specific to plugin behavior
    /// - Returns: An AuthPublisher with the results of the operation
    func forgetDevice(
        _ device: AuthDevice? = nil,
        options: AuthForgetDeviceOperation.Request.Options? = nil
    ) -> AuthPublisher<Void> {
        Future { promise in
            _ = self.forgetDevice(device, options: options) { promise($0) }
        }.eraseToAnyPublisher()
    }

    /// Remember the current user device
    ///
    /// - Parameters:
    ///   - options: Parameters specific to plugin behavior
    /// - Returns: An AuthPublisher with the results of the operation
    func rememberDevice(
        options: AuthRememberDeviceOperation.Request.Options? = nil
    ) -> AuthPublisher<Void> {
        Future { promise in
            _ = self.rememberDevice(options: options) { promise($0) }
        }.eraseToAnyPublisher()
    }

}
