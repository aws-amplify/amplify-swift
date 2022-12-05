//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import ClientRuntime

extension GlobalSignOutOutputResponse: Codable {

    public init(from decoder: Swift.Decoder) throws {
        self.init()
    }

    public func encode(to encoder: Encoder) throws {
        fatalError("Not supported")
    }

}
