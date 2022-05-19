//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension BookAuthor {

    // MARK: - CodingKeys
    public enum CodingKeys: String, ModelKey {
        case id
        case book
        case author
    }

    public static let keys = CodingKeys.self

    // MARK: - ModelSchema

    public static let schema = defineSchema { model in
        let bookAuthor = BookAuthor.keys

        model.fields(
            .id(),
            .belongsTo(bookAuthor.book,
                     ofType: Book.self,
                     associatedWith: Book.keys.authors),
            .belongsTo(bookAuthor.author,
                     ofType: Author.self,
                     associatedWith: Author.keys.books)
        )
    }

}
