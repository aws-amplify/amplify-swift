//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSComprehend
//import AWSTranscribeStreaming

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


    // TODO: remove/refactor/rename after adding transcribe streaming support
    /*
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
     */
}
