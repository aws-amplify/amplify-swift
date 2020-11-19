//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import AWSCognitoAuthPlugin

class MockAuthDeviceServiceBehavior: AuthDeviceServiceBehavior {

    func fetchDevices(request: AuthFetchDevicesRequest,
                      completionHandler: @escaping (Result<[AuthDevice], AuthError>) -> Void) {
        // Incomplete implementation
    }

    func forgetDevice(request: AuthForgetDeviceRequest,
                      completionHandler: @escaping (Result<Void, AuthError>) -> Void) {
        // Incomplete implementation
    }

    func rememberDevice(request: AuthRememberDeviceRequest,
                        completionHandler: @escaping (Result<Void, AuthError>) -> Void) {
        // Incomplete implementation
    }

}
