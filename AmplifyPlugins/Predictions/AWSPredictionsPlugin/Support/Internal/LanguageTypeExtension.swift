//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSComprehend
import AWSTranscribeStreaming

extension LanguageType {

    func toComprehendLanguage() -> AWSComprehendLanguageCode {
        switch self {
        case .english:
            return .en
        case .italian:
            return .it
        case .spanish:
            return .es
        case .french:
            return .fr
        case .german:
            return .de
        case .portuguese:
            return .pt
        default:
            return .unknown
        }
    }

    func toSyntaxLanguage() -> AWSComprehendSyntaxLanguageCode {
        switch self {
        case .english:
            return .en
        case .italian:
            return .it
        case .spanish:
            return .es
        case .french:
            return .fr
        case .german:
            return .de
        case .portuguese:
            return .pt
        default:
            return .unknown
        }
    }

    func toTranscribeLanguage() -> AWSTranscribeStreamingLanguageCode {
        switch self {
        case .usEnglish,
             .english:
            return .enUS
        case .french:
            return .frFR
        case .canadianFrench:
            return .frCA
        case .britishEnglish:
            return .enGB
        case .usSpanish:
            return .esUS
        default:
            return .unknown
        }
    }
}
