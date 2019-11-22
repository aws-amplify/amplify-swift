//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSComprehend

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
}
