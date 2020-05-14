//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSMobileClient

extension Tokens {
    func toAWSCognitoUserPoolTokens() -> AWSCognitoUserPoolTokens {
        let cognitoToken = AWSCognitoUserPoolTokens(idToken: idToken?.tokenString ?? "",
                                                    accessToken: accessToken?.tokenString ?? "",
                                                    refreshToken: refreshToken?.tokenString ?? "")
        return cognitoToken
    }
}
