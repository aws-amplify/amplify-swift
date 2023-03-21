//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

// This generated model is NOT accurate.
// We're using a `class` in order to circumvent a
// circular reference issues with structs and a
// hasOne+belongsTo relationship
// swiftlint:disable:next todo
// TODO: replace this with a struct when the above issue is solved.
public class UserProfile: Model {

    public let id: String

    // belongsTo(associatedWith: "profile")
    public var account: UserAccount

    public init(id: String = UUID().uuidString,
                account: UserAccount) {
        self.id = id
        self.account = account
    }
}
