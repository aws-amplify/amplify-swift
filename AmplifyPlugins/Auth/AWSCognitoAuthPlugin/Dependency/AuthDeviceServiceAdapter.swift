//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

struct AuthDeviceServiceAdapter: AuthDeviceServiceBehavior {

    let awsMobileClient: AWSMobileClientBehavior

    init(awsMobileClient: AWSMobileClientBehavior) {
        self.awsMobileClient = awsMobileClient
    }

    func fetchDevices(request: AuthFetchDevicesRequest,
                      completionHandler: @escaping (Result<[AuthDevice], AuthError>) -> Void) {

        awsMobileClient.listDevices { result, error in
            if let error = error {
                let authError = AuthErrorHelper.toAuthError(error)
                completionHandler(.failure(authError))
                return
            }
            guard let result = result else {
                // This should not happen, return an unknown error.
                let error = AuthError.unknown("Could not read result from fetchDevices operation")
                completionHandler(.failure(error))
                return
            }
            let deviceList = result.devices?.reduce(into: [AuthDevice]()) {
                $0.append($1.toAWSAuthDevice())
            }
            completionHandler(.success(deviceList ?? []))
        }
    }

    func forgetDevice(request: AuthForgetDeviceRequest,
                      completionHandler: @escaping (Result<Void, AuthError>) -> Void) {

        guard let device = request.device else {
            awsMobileClient.forgetCurrentDevice { error in
                if let error = error {
                    let authError = AuthErrorHelper.toAuthError(error)
                    completionHandler(.failure(authError))
                    return
                }
                completionHandler(.success(()))
            }
            return
        }
        awsMobileClient.forgetDevice(deviceId: device.id) { error in
            if let error = error {
                let authError = AuthErrorHelper.toAuthError(error)
                completionHandler(.failure(authError))
                return
            }
            completionHandler(.success(()))
        }
        return

    }

    func rememberDevice(request: AuthRememberDeviceRequest,
                        completionHandler: @escaping (Result<Void, AuthError>) -> Void) {
        awsMobileClient.updateDeviceStatus(remembered: true) { _, error in
            if let error = error {
                let authError = AuthErrorHelper.toAuthError(error)
                completionHandler(.failure(authError))
                return
            }
            completionHandler(.success(()))
        }
    }
}
