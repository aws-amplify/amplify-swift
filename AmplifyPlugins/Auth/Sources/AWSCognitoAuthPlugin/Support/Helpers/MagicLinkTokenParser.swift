//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct MagicLinkTokenParser {

    static func extractUserName(from token: String) throws -> String {
        let tokenSplit = token.split(separator: ".")
        guard tokenSplit.count == 2 else {
            throw SignInError.invalidServiceResponse(
                message: "Malformed magic link token")
        }
        let base64 = tokenSplit[0]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let paddedLength = base64.count + (4 - (base64.count % 4)) % 4

        let base64Padding = base64.padding(toLength: paddedLength, withPad: "=", startingAt: 0)
        guard let encodedData = Data(base64Encoded: base64Padding,
                                     options: .ignoreUnknownCharacters),
              let jsonObject = try? JSONSerialization.jsonObject(
                with: encodedData,
                options: []) as? [String: Any] else {
            throw SignInError.invalidServiceResponse(
                message: "Unable to to decode magic link token")
        }

        guard let username = jsonObject["username"] as? String else {
            throw SignInError.invalidServiceResponse(
                message: "Did not find username object in magic link token")
        }

        return username
    }
}
