//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct Section: Embeddable {
    var name: String
    var number: Double
}

extension Section {
    public enum CodingKeys: CodingKey {
        case name
        case number
    }

    public static let keys = CodingKeys.self

    public static let schema = defineSchema { embedded in
        let section = Section.keys
        embedded.fields(.field(section.name, is: .required, ofType: .string),
                       .field(section.number, is: .required, ofType: .double))
    }
}
