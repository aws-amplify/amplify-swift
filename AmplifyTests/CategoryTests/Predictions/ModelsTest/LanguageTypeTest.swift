//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class LanguageTypeTest: XCTestCase, @unchecked Sendable {

    func testInitialization() {
        let language = Predictions.Language(code: "en")
        XCTAssertEqual(language, .english)
    }

    func testInitWithLocale() {
        let currentLocale = Locale.current
        let languageType = Predictions.Language(locale: currentLocale)
        XCTAssertNotEqual(languageType, .undetermined)
    }

    func testConverToLocale() {
        let language = Predictions.Language.afrikaans
        let locale = Locale(identifier: language.code)
        XCTAssertEqual(locale.languageCode, "af")
    }
}
