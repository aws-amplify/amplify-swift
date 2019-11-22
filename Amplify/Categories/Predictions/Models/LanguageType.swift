//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Language type supported by Predictions category
public enum LanguageType: String {
    case english = "en"
    case italian = "it"
    case german = "de"
    case french = "fr"
    case spanish = "es"
    case chinese = "zh"
    case russian = "ru"
    case portuguese = "pt"
    case undetermined
}

extension LanguageType {

    public init(locale: Locale) {

        switch locale.languageCode {
        case "en":
            self = .english
        case "it":
            self = .italian
        case "de":
            self = .german
        case "fr":
            self = .french
        case "es":
            self = .spanish
        case "zh":
            self = .chinese
        case "ru":
            self = .russian
        case "pt":
            self = .portuguese
        default:
            self = .undetermined
        }
    }
}
