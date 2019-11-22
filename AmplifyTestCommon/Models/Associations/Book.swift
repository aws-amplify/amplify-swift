//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public class Book: Model {

    public let id: Model.Identifier

    // hasMany
    public let authors: [BookAuthor]

    public init(id: String = UUID().uuidString,
                authors: [BookAuthor] = []) {
        self.id = id
        self.authors = authors
    }
}
