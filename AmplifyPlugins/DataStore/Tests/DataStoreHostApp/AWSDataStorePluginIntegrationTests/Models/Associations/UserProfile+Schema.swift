//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public extension UserProfile {

    // MARK: - CodingKeys
    enum CodingKeys: String, ModelKey {
        case id
        case account
    }

    static let keys = CodingKeys.self

    // MARK: - ModelSchema

    static let schema = defineSchema { model in
        let profile = UserProfile.keys

        model.fields(
            .id(),
            .belongsTo(
                profile.account,
                ofType: UserAccount.self,
                associatedWith: UserAccount.keys.profile
            )
        )
    }

}
