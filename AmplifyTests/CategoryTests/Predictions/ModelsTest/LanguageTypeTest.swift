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
        let enLanguage = LanguageType(rawValue: "en")
        XCTAssertEqual(enLanguage, LanguageType.english)
    }

    func testInitWithLocale() {
        let currentLocale = Locale.current
        let languageType = LanguageType(locale: currentLocale)
        XCTAssertNotEqual(languageType, LanguageType.undetermined)
    }

    func testConvertEnglishToLocale() {
        let enLangauage = LanguageType.afrikaans
        let locale = Locale(identifier: enLangauage.rawValue)
        XCTAssertEqual(locale.languageCode, "af")
    }
}
