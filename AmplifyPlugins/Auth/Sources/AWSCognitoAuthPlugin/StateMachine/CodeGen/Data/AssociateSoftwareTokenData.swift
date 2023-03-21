//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct AssociateSoftwareTokenData {

    let secretCode: String
    let session: String

}

extension AssociateSoftwareTokenData: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "secretCode": secretCode.masked(),
            "session": session.masked()
        ]
    }
}

extension AssociateSoftwareTokenData: Codable { }

extension AssociateSoftwareTokenData: Equatable { }
