//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

protocol AuthDeviceServiceBehavior {

    func fetchDevices(request: AuthFetchDevicesRequest,
                      completionHandler: @escaping (Result<[AuthDevice], AmplifyAuthError>) -> Void)

    func forgetDevice(request: AuthForgetDeviceRequest,
                      completionHandler: @escaping (Result<Void, AmplifyAuthError>) -> Void)

    func rememberDevice(request: AuthRememberDeviceRequest,
                        completionHandler: @escaping (Result<Void, AmplifyAuthError>) -> Void)
}
