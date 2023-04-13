//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSComprehend

extension ComprehendClientTypes.PartOfSpeechTagType {
    // swiftlint:disable cyclomatic_complexity
    func getSpeechType() -> SpeechType {
        switch self {
        case .sdkUnknown:
            return .unknown
        case .adj:
            return .adjective
        case .adp:
            return .adposition
        case .conj:
            return .conjunction
        case .cconj:
            return .coordinatingConjunction
        case .det:
            return .determiner
        case .intj:
            return .interjection
        case .noun:
            return .noun
        case .num:
            return .numeral
        case .o:
            return .other
        case .part:
            return .particle
        case .pron:
            return .pronoun
        case .propn:
            return .properNoun
        case .punct:
            return .punctuation
        case .sconj:
            return .subordinatingConjunction
        case .sym:
            return .symbol
        case .verb:
            return .verb
        case .adv:
            return .adverb
        case .aux:
            return .auxiliary
        }
    }
}
