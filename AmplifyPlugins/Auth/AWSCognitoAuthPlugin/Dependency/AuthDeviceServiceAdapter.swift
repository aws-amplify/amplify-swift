//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
#if COCOAPODS
import AWSMobileClient
#else
import AWSMobileClientXCF
#endif

struct AuthDeviceServiceAdapter: AuthDeviceServiceBehavior {

    let awsMobileClient: AWSMobileClientBehavior

    init(awsMobileClient: AWSMobileClientBehavior) {
        self.awsMobileClient = awsMobileClient
    }

    func fetchDevices(request: AuthFetchDevicesRequest,
                      completionHandler: @escaping (Result<[AuthDevice], AuthError>) -> Void) {

        awsMobileClient.listDevices { result, error in
            if let authError = mapToAuthError(error) {
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
                if let authError = mapToAuthError(error) {
                    completionHandler(.failure(authError))
                    return
                }
                completionHandler(.success(()))
            }
            return
        }
        awsMobileClient.forgetDevice(deviceId: device.id) { error in
            if let authError = mapToAuthError(error) {
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
            if let authError = mapToAuthError(error) {
                completionHandler(.failure(authError))
                return
            }
            completionHandler(.success(()))
        }
    }

    private func mapToAuthError(_ error: Error?) -> AuthError? {
        guard let error = error else {
            return nil
        }

        // `.notSignedIn` should be handled explicitly and not as part of AuthErrorHelper
        if let awsMobileClientError = error as? AWSMobileClientError,
            case .notSignedIn = awsMobileClientError {
            return AuthError.signedOut(
                AuthPluginErrorConstants.userSignedOutError.errorDescription,
                AuthPluginErrorConstants.userSignedOutError.recoverySuggestion,
                error
            )
        } else {
            return AuthErrorHelper.toAuthError(error)
        }
    }
}
