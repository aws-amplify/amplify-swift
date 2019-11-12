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
        // TODO: Fill the right language codes below
        switch self {
        case .english:
            return .en
        case .italian:
            return .it
        case .undetermined:
            return .unknown
        }
    }

    func toSyntaxLanguage() -> AWSComprehendSyntaxLanguageCode {
        // TODO: Fill the right language codes below
        switch self {
        case .english:
            return .en
        case .italian:
            return .it
        case .undetermined:
            return .unknown
        }
    }
}
