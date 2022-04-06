//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

@testable import Amplify
@testable import AWSDataStorePlugin
@testable import SQLite

class SQLModelValueConverterTests: BaseDataStoreTests {

    private let testId = "df5dd4a4-34f8-4974-8a37-2617cf8dafe1"

    private let testDateString = "2020-02-02Z"

    private var testDate: Temporal.Date {
        // swiftlint:disable:next force_try
        return try! Temporal.Date(iso8601String: testDateString)
    }

    private var exampleModel: ExampleWithEveryType {
        // non-model type
        let nonModelExample = ExampleNonModelType(someString: "string", someEnum: .foo)

        // example model
        let example = ExampleWithEveryType(id: testId,
                                           stringField: "string",
                                           intField: 20,
                                           doubleField: 6.5,
                                           boolField: true,
                                           dateField: testDate,
                                           enumField: .bar,
                                           nonModelField: nonModelExample,
                                           arrayOfStringsField: ["foo", "bar"])
        return example
    }

    /// - Given: a `ExampleWithEveryType` model instance
    /// - When:
    ///   - the `sqlValues()` is called
    /// - Then:
    ///   - the result should be a SQLite `[Binding]` with the expected types:
    ///     - enum values must be strings
    ///     - arrays must be strings
    ///     - non-model types must be strings
    ///     - bool must be `Int` (1 or 0)
    ///     - the remaining types should not change
    func testModelWithEveryTypeConversionToBindings() {
        let nonModelJSON = "{\"someString\":\"string\",\"someEnum\":\"foo\"}"
        let example = exampleModel

        // convert model to SQLite Bindings
        let bindings = example.sqlValues(modelSchema: example.schema)

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

    /// - Given: a `ExampleWithEveryType` model instance
    /// - When:
    ///   - the `Amplify.DataStore.save(example)` is called, followed by a
    ///   `Amplify.DataStore.query(ExampleWithEveryType, byId: id)`
    /// - Then:
    ///   - the returning object must contain exatly the same values as the saved object,
    ///   including correct enums and non-model types
    func testInsertAndSelectExampleWithEveryType() {
        let example = exampleModel

        // save it
        Amplify.DataStore.save(exampleModel) { saveResult in
            switch saveResult {
            case .success:
                Amplify.DataStore.query(ExampleWithEveryType.self, byId: example.id) {
                    switch $0 {
                    case .success(let result):
                        // then check if the queried version has the correct values
                        guard let savedExample = result else {
                            XCTFail("ExampleWithEveryType with id \(example.id) not found")
                            return
                        }
                        XCTAssertEqual(savedExample.arrayOfStringsField, example.arrayOfStringsField)
                        XCTAssertEqual(savedExample.boolField, example.boolField)
                        XCTAssertEqual(savedExample.dateField.iso8601String, example.dateField.iso8601String)
                        XCTAssertEqual(savedExample.doubleField, example.doubleField)
                        XCTAssertEqual(savedExample.enumField, example.enumField)
                        XCTAssertEqual(savedExample.id, example.id)
                        XCTAssertEqual(savedExample.intField, example.intField)
                        XCTAssertEqual(savedExample.stringField, example.stringField)
                        // non-model fields
                        XCTAssertEqual(savedExample.nonModelField.someEnum, example.nonModelField.someEnum)
                        XCTAssertEqual(savedExample.nonModelField.someString, example.nonModelField.someString)
                    case .failure(let error):
                        XCTFail(error.errorDescription)
                    }
                }
            case .failure(let error):
                XCTFail(error.errorDescription)
            }
        }
    }

}
