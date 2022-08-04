//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension Book {

    // MARK: - CodingKeys
    public enum CodingKeys: String, ModelKey {
        case id
        case authors
    }

    public static let keys = CodingKeys.self

    // MARK: - ModelSchema

    public static let schema = defineSchema { model in
        let book = Book.keys

        model.fields(
            .id(),
            .hasMany(book.authors,
                     ofType: BookAuthor.self,
                     associatedWith: BookAuthor.keys.author)
        )
    }

}
