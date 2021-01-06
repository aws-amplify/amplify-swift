//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension Author {

    // MARK: - CodingKeys
    public enum CodingKeys: String, ModelKey {
        case id
        case books
    }

    public static let keys = CodingKeys.self

    // MARK: - ModelSchema

    public static let schema = defineSchema { model in
        let author = Author.keys

        model.fields(
            .id(),
            .hasMany(author.books,
                     ofType: BookAuthor.self,
                     associatedWith: BookAuthor.keys.book)
        )
    }

}
