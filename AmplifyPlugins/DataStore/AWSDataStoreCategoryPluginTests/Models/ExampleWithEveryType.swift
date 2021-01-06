//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public enum ExampleEnum: String, EnumPersistable {
    case foo
    case bar
}

public struct ExampleNonModelType: Codable {

    public let someString: String
    public let someEnum: ExampleEnum
}

public struct ExampleWithEveryType: Model {

    public let id: String
    public var stringField: String
    public var intField: Int
    public var doubleField: Double
    public var boolField: Bool
    public var dateField: Temporal.Date
    public var enumField: ExampleEnum
    public var nonModelField: ExampleNonModelType
    public var arrayOfStringsField: [String]

}
