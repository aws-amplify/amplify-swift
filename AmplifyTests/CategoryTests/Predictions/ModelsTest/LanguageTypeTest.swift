//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify

class LanguageTypeTest: XCTestCase {

    func testInitialization() {
        let enLanguage = Predictions.Language(rawValue: "en")
        XCTAssertEqual(enLanguage, Predictions.Language.english)
    }

    func testInitWithLocale() {
        let currentLocale = Locale.current
        let languageType = Predictions.Language(locale: currentLocale)
        XCTAssertNotEqual(languageType, Predictions.Language.undetermined)
    }

    func testConvertEnglishToLocale() {
        let enLangauage = Predictions.Language.afrikaans
        let locale = Locale(identifier: enLangauage.rawValue)
        XCTAssertEqual(locale.languageCode, "af")
    }
}
