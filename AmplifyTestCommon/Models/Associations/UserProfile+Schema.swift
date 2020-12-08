//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension UserProfile {

    // MARK: - CodingKeys
    public enum CodingKeys: String, ModelKey {
        case id
        case account

        public var modelName: String {
            return "UserProfile"
        }
    }

    public static let keys = CodingKeys.self

    // MARK: - ModelSchema

    public static let schema = defineSchema { model in
        let profile = UserProfile.keys

        model.fields(
            .id(),
            .belongsTo(profile.account,
                       ofType: UserAccount.self,
                       associatedWith: UserAccount.keys.profile)
        )
    }

}
