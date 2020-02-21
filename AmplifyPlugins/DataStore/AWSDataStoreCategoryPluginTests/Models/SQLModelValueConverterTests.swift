//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

@testable import Amplify
@testable import AWSDataStoreCategoryPlugin

class SQLModelValueConverterTests: XCTestCase {

    let testDateString = "2020-02-02T08:00:00.000Z"

    var testDate: Date {
        return testDateString.iso8601Date!
    }

    func testModelWithEveryTypeConversionToBindings() {

        // non-model type
        let nonModelExample = ExampleNonModelType(someString: "string", someEnum: .foo)
        let nonModelJSON = "{\"someString\":\"string\",\"someEnum\":\"foo\"}"

        // example model
        let example = ExampleWithEveryType(id: "df5dd4a4-34f8-4974-8a37-2617cf8dafe1",
                                           stringField: "string",
                                           intField: 20,
                                           doubleField: 6.5,
                                           boolField: true,
                                           dateField: testDate,
                                           enumField: .bar,
                                           nonModelField: nonModelExample,
                                           arrayOfStringsField: ["foo", "bar"])

        // convert model to SQLite Bindings
        let bindings = example.sqlValues()

        // columns are ordered, so check if the values are correct and in the right index
        XCTAssertEqual(bindings.count, ExampleWithEveryType.schema.columns.count)
        XCTAssertEqual(bindings[0] as? String, example.id) // id
        XCTAssertEqual(bindings[1] as? String, "[\"foo\",\"bar\"]") // arrayOfStringsField
        XCTAssertEqual(bindings[2] as? Int, 1) // boolField
        XCTAssertEqual(bindings[3] as? String, testDateString) // dateField
        XCTAssertEqual(bindings[4] as? Double, 6.5) // doubleField
        XCTAssertEqual(bindings[5] as? String, "bar") // enumField
        XCTAssertEqual(bindings[6] as? Int, 20) // intField
        XCTAssertEqual(bindings[7] as? String, nonModelJSON) // nonModelField
    }

}
