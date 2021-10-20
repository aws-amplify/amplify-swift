//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSCore
import AWSPluginsCore

extension AuthorizationProviderAdapter {

    func fetchSignedOutSession( _ completionHandler: @escaping SessionCompletionHandler) {
        awsMobileClient.getAWSCredentials { awsCredentials, error in

            guard error == nil else {
                let authSession = AuthCognitoSignedOutSessionHelper.makeSignedOutSession(withError: error!)
                completionHandler(.success(authSession))
                return
            }

            guard let credentials = awsCredentials else {
                // This should not happen, throw an unknown error.
                // Since we couldnot fetch aws credentials, we stop here to avoid sending partial information.
                let error = AuthError.unknown("""
                    Could not fetch AWS credentials, but there was no error reported back from
                    AWSMobileClient.getAWSCredentials call.
                    """)
                let authSession = AuthCognitoSignedOutSessionHelper.makeSignedOutSession(withError: error)
                completionHandler(.success(authSession))
                return
            }

            // At this point we have valid aws credentials. This credential was fetched using an identity id. So next
            // step is to retreive the available identity id and return.
            self.retreiveIdentityId(withCredentials: credentials,
                                    completionHandler: completionHandler)
        }
    }

    /// Build the session after credentials has been retreived.
    ///
    /// If fetching aws credentials is successful, the identityId would have been cached. So getIdentityID should
    /// return the latest id.
    private func retreiveIdentityId(withCredentials awsCredentials: AWSCredentials,
                                    completionHandler: @escaping SessionCompletionHandler) {

        awsMobileClient.getIdentityId().continueWith { (task) -> Any? in
            guard task.error == nil else {
                let authSession = AuthCognitoSignedOutSessionHelper.makeSignedOutSession(withError: task.error!)
                completionHandler(.success(authSession))
                return nil
            }
            guard let identityId = task.result as String? else {
                let error = AuthError.unknown("""
                    Could not retreive identity id, but there was no error reported back from
                    AWSMobileClient.getIdentityId call.
                    """)
                let authSession = AuthCognitoSignedOutSessionHelper.makeSignedOutSession(withError: error)
                completionHandler(.success(authSession))
                return nil
            }

            do {
                let amplifyAWSCredentials = try awsCredentials.toAmplifyAWSCredentials()
                let authSession = AuthCognitoSignedOutSessionHelper.makeSignedOutSession(
                    identityId: identityId,
                    awsCredentials: amplifyAWSCredentials
                )
                completionHandler(.success(authSession))
                return nil

            } catch {
                let authSession = AuthCognitoSignedOutSessionHelper.makeSignedOutSession(withError: error)
                completionHandler(.success(authSession))
                return nil
            }

        }
    }
}
