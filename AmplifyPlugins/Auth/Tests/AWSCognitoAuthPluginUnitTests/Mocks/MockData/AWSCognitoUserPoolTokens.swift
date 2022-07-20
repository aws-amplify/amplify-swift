//
//  File.swift
//  
//
//  Created by Roy, Jithin on 7/22/22.
//

import Foundation
import AWSCognitoAuthPlugin



extension AWSCognitoUserPoolTokens {

    static var mockData: AWSCognitoUserPoolTokens {
        let tokenData = [
            "sub": "1234567890",
            "name": "John Doe",
            "iat": "1516239022",
            "exp": String(Date(timeIntervalSinceNow: 121).timeIntervalSince1970)
        ]
        return AWSCognitoUserPoolTokens(idToken: CognitoAuthTestHelper.buildToken(for: tokenData),
                                              accessToken: CognitoAuthTestHelper.buildToken(for: tokenData),
                                              refreshToken: "refreshToken",
                                              expiresIn: 121)
    }
}

