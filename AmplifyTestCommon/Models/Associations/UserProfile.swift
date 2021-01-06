//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public class UserProfile: Model {

    public let id: Model.Identifier

    // belongsTo(associatedWith: "profile")
    public var account: UserAccount

    public init(id: String = UUID().uuidString,
                account: UserAccount) {
        self.id = id
        self.account = account
    }
}
