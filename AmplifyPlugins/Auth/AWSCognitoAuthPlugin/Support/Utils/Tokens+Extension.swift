//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if COCOAPODS
import AWSMobileClient
#else
import AWSMobileClientXCF
#endif

extension Tokens {
    func toAWSCognitoUserPoolTokens() -> AWSCognitoUserPoolTokens {
        let cognitoToken = AWSCognitoUserPoolTokens(idToken: idToken?.tokenString ?? "",
                                                    accessToken: accessToken?.tokenString ?? "",
                                                    refreshToken: refreshToken?.tokenString ?? "")
        return cognitoToken
    }
}
