//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@preconcurrency import Amplify
import Foundation

public extension UserAccount {

    // MARK: - CodingKeys
    enum CodingKeys: String, ModelKey {
        case id
        case profile
    }

    static let keys = CodingKeys.self

    // MARK: - ModelSchema

    static let schema = defineSchema { model in
        let account = UserAccount.keys

        model.fields(
            .id(),
            .hasOne(
                account.profile,
                is: .optional,
                ofType: UserProfile.self,
                associatedWith: UserProfile.CodingKeys.account
            )
        )
    }

}
