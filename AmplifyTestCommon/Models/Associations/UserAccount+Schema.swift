//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension UserAccount {

    // MARK: - CodingKeys
    public enum CodingKeys: String, ModelKey {
        case id
        case profile
    }

    public static let keys = CodingKeys.self

    // MARK: - ModelSchema

    public static let schema = defineSchema { model in
        let account = UserAccount.keys

        model.fields(
            .id(),
            .hasOne(account.profile,
                    is: .optional,
                    ofType: UserProfile.self,
                    associatedWith: UserProfile.CodingKeys.account)
        )
    }

}
