//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import AWSCognitoAuthPlugin

class MockAuthDeviceServiceBehavior: AuthDeviceServiceBehavior {

    var interactions: [String] = []

    // swiftlint:disable line_length
    var fetchDevicesHandler: (AuthFetchDevicesRequest, (Result<[AuthDevice], AuthError>) -> Void) -> Void = { _, completion in
        completion(.success([]))
    }

    func fetchDevices(request: AuthFetchDevicesRequest,
                      completionHandler: @escaping (Result<[AuthDevice], AuthError>) -> Void) {
        interactions.append(#function)
        fetchDevicesHandler(request, completionHandler)
    }

    var forgetDeviceHandler: (AuthForgetDeviceRequest, (Result<Void, AuthError>) -> Void) -> Void = { _, completion in
        completion(.success(()))
    }

    func forgetDevice(request: AuthForgetDeviceRequest,
                      completionHandler: @escaping (Result<Void, AuthError>) -> Void) {
        interactions.append(#function)
        forgetDeviceHandler(request, completionHandler)
    }

    // swiftlint:disable line_length
    var rememberDeviceHandler: (AuthRememberDeviceRequest, (Result<Void, AuthError>) -> Void) -> Void = { _, completion in
        completion(.success(()))
    }

    func rememberDevice(request: AuthRememberDeviceRequest,
                        completionHandler: @escaping (Result<Void, AuthError>) -> Void) {
        interactions.append(#function)
        rememberDeviceHandler(request, completionHandler)
    }

}
