//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public class UserAccount: Model {

    public let id: Model.Identifier

    // hasOne(associatedWith: "account")
    public var profile: UserProfile?

    public init(id: String = UUID().uuidString,
                profile: UserProfile? = nil) {
        self.id = id
        self.profile = profile
    }
}
