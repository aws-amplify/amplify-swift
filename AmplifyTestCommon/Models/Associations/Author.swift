//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public class Author: Model {

    public let id: Model.Identifier

    // hasMany(associatedWith: "author")
    public var books: List<BookAuthor>

    public init(id: String = UUID().uuidString,
                books: List<BookAuthor> = []) {
        self.id = id
        self.books = books
    }
}
