//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation

/// Language type supported by Predictions category
public enum LanguageType: String {
    // TODO: Add the whole list
    case english = "en"
    case italian = "it"
    case undetermined
}

extension LanguageType {

    public init(locale: Locale) {

        switch locale.languageCode {
        case "en":
            self = .english
        case "it":
            self = .italian
        default:
            self = .undetermined
        }
    }
}
