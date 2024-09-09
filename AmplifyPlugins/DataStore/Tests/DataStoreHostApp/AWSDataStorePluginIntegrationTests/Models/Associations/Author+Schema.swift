//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public extension Author {

    // MARK: - CodingKeys
    enum CodingKeys: String, ModelKey {
        case id
        case books
    }

    static let keys = CodingKeys.self

    // MARK: - ModelSchema

    static let schema = defineSchema { model in
        let author = Author.keys

        model.fields(
            .id(),
            .hasMany(
                author.books,
                ofType: BookAuthor.self,
                associatedWith: BookAuthor.keys.book
            )
        )
    }

}
