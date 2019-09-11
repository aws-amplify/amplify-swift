//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSMobileClient

class AWSAuthService: AWSAuthServiceBehavior {

    var mobileClient: AWSMobileClientBehavior

    init(mobileClient: AWSMobileClientBehavior? = nil) {
        let mobileClient = mobileClient ?? AWSMobileClientAdapter(AWSMobileClient.sharedInstance())
        self.mobileClient = mobileClient
    }

    func getCognitoCredentialsProvider() -> AWSCognitoCredentialsProvider {
        return mobileClient.getCognitoCredentialsProvider()
    }

    func getIdentityId() -> Result<String, AuthError> {
        let task = mobileClient.getIdentityId()
        task.waitUntilFinished()

        guard task.error == nil else {
            if let error = task.error! as? AWSMobileClientError {
                return .failure(map(error))
            }

            return .failure(AuthError.identity(AuthErrorConstants.contentTypeIsEmpty.ErrorDescription,
                                               AuthErrorConstants.contentTypeIsEmpty.RecoverySuggestion))
        }

        guard let identityId = task.result else {
            let error = AuthError.identity(AuthErrorConstants.contentTypeIsEmpty.ErrorDescription,
                                           AuthErrorConstants.contentTypeIsEmpty.RecoverySuggestion)
            return .failure(error)
        }

        return .success(identityId as String)
    }

    private func map(_ error: AWSMobileClientError) -> AuthError {
        switch error {
        case .identityIdUnavailable(let message):
            return AuthError.identity(message, error.localizedDescription)
        case .guestAccessNotAllowed(let message):
            return AuthError.identity(message, error.localizedDescription)
        default:
            return AuthError.identity(error.localizedDescription, "")
        }
    }
}
