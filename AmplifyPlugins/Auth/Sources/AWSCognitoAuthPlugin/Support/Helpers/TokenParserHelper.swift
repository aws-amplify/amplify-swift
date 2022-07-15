//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct TokenParserHelper {

    static func getAuthUser(accessToken: String) throws -> AWSAuthUser {
        let tokenSplit = accessToken.split(separator: ".")
        guard accessToken.count > 2 else {
            throw SignInError.hostedUI(.tokenParsing)
        }
        let base64 = tokenSplit[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let paddedLength = base64.count + (4 - (base64.count % 4)) % 4

        let base64Padding = base64.padding(toLength: paddedLength, withPad: "=", startingAt: 0)
        guard let encodedData = Data(base64Encoded: base64Padding,
                                     options: .ignoreUnknownCharacters),
              let jsonObject = try? JSONSerialization.jsonObject(
                with: encodedData,
                options: []) as? [String: Any]
        else {
            throw SignInError.hostedUI(.tokenParsing)
        }

        let username = jsonObject["username"] as? String ?? ""
        let sub = jsonObject["sub"] as? String ?? ""
        return AWSAuthUser(username: username, userId: sub)
    }
}
