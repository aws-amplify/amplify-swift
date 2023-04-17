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

    func toComprehendLanguage() -> ComprehendClientTypes.LanguageCode {
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
            return .sdkUnknown(rawValue)
        }
    }

    func toSyntaxLanguage() -> ComprehendClientTypes.SyntaxLanguageCode {
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
            return .sdkUnknown(rawValue)
        }
    }


    func toTranscribeLanguage() -> TranscribeStreamingClientTypes.LanguageCode {
        switch self {
        case .usEnglish,
             .english:
            return .enUs
        case .french:
            return .frFr
        case .canadianFrench:
            return .frCa
        case .britishEnglish:
            return .enGb
        case .usSpanish:
            return .esUs
        default:
            return .sdkUnknown(rawValue)
        }
    }
}
