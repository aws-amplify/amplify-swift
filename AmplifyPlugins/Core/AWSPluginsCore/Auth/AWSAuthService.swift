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

    public init() {}

    public func getCredentialsProvider() -> AWSCredentialsProvider {
        return AmplifyAWSCredentialsProvider()
    }

    public func getIdentityId() -> Result<String, AuthError> {
        var result: Result<String, AuthError>?
        let semaphore = DispatchSemaphore(value: 0)
        _ = Amplify.Auth.fetchAuthSession { event in
            defer {
                semaphore.signal()
            }

            switch event {
            case .success(let session):
                result = (session as? AuthCognitoIdentityProvider)?.getIdentityId()
            case .failure(let error):
                result = .failure(error)

            }
        }
        semaphore.wait()
        guard let validResult = result else {
            return .failure(AuthError.unknown("""
            Did not receive a valid response from fetchAuthSession for identityId.
            """))
        }
        return validResult
    }

    public func getToken() -> Result<String, AuthError> {
        var result: Result<String, AuthError>?
        let semaphore = DispatchSemaphore(value: 0)
        _ = Amplify.Auth.fetchAuthSession { [weak self] event in

            defer {
                semaphore.signal()
            }

            switch event {
            case .success(let session):
                result = self?.getTokenString(from: session)
            case .failure(let error):
                result = .failure(error)

            }
        }
        semaphore.wait()
        guard let validResult = result else {
            return .failure(AuthError.unknown("""
            Did not receive a valid response from fetchAuthSession for get token.
            """))
        }
        return validResult
    }

    private func getTokenString(from authSession: AuthSession) -> Result<String, AuthError>? {
        if let result = (authSession as? AuthCognitoTokensProvider)?.getCognitoTokens() {
            switch result {
            case .success(let tokens):
                return .success(tokens.idToken)
            case .failure(let error):
                return .failure(error)
            }
        }
        return nil
    }
}
