//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSMobileClient

public class AWSAuthService: AWSAuthServiceBehavior {

    var mobileClient: AWSMobileClientBehavior!

    public convenience init() {
        self.init(mobileClient: nil)
    }

    init(mobileClient: AWSMobileClientBehavior? = nil) {
        let mobileClient = mobileClient ?? AWSMobileClientAdapter(AWSMobileClient.default())
        self.mobileClient = mobileClient
    }

    public func getCognitoCredentialsProvider() -> AWSCognitoCredentialsProvider {
        return mobileClient.getCognitoCredentialsProvider()
    }

    public func getIdentityId() -> Result<String, AuthError> {
        let task = mobileClient.getIdentityId()
        task.waitUntilFinished()

        guard task.error == nil else {
            if let error = task.error! as? AWSMobileClientError {
                return .failure(map(error))
            }

            return .failure(AuthError.unknown("Some error occuring retrieving the IdentityId."))
        }

        guard let identityId = task.result else {
            let error = AuthError.unknown("Got successful response but missing IdentityId in the result.")
            return .failure(error)
        }

        return .success(identityId as String)
    }

    public func getToken() -> Result<String, AuthError> {
        var jwtToken: String?
        var authError: AuthError?

        let semaphore = DispatchSemaphore(value: 0)
        mobileClient.getTokens { [weak self] tokens, error in
            if let error = error as? AWSMobileClientError {
                authError = self?.map(error)
            } else if let token = tokens {
                jwtToken = token.idToken?.tokenString
            }

            semaphore.signal()
        }
        semaphore.wait()
        guard authError == nil else {
            if let error = authError {
                return .failure(error)
            }

            return .failure(AuthError.unknown("not sure what happened trying to get failure for retrieving token"))
        }
        guard let token = jwtToken else {
            return .failure(AuthError.unknown("not sure what happened getting the jwtToken"))
        }

        return .success(token)
    }

    /// Used for testing only. Invoking this method outside of a testing scope has undefined behavior.
    public func reset() {
        mobileClient = nil
    }

    private func map(_ error: AWSMobileClientError) -> AuthError {
        // TODO: Use main auth error from Auth plugin
        return AuthError.unknown(error.message)
    }

}
