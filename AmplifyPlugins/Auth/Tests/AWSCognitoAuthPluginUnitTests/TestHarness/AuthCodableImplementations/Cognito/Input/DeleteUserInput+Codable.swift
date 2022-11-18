//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import ClientRuntime

extension DeleteUserInput: Decodable {

    public init(from decoder: Decoder) throws {
        self.init()
    }
}
