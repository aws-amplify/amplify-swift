//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPolly

typealias AWSPollyErrorString = (errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion)

struct AWSPollyErrorMessage {
    
    // swiftlint:disable cyclomatic_complexity
    static func map(_ errorType: AWSPollyErrorType) -> PredictionsError? {
        switch errorType {
        case .engineNotSupported:
            break
        case .invalidLexicon:
            break
        case .invalidNextToken:
            break
        case .invalidSampleRate:
            break
        case .invalidSsml:
            break
        case .invalidTaskId:
            break
        case .languageNotSupported:
            break
        case .lexiconNotFound:
            break
        case .lexiconSizeExceeded:
            break
        case .marksNotSupportedForFormat:
            break
        case .maxLexemeLengthExceeded:
            break
        case .maxLexiconsNumberExceeded:
            break
        case .serviceFailure:
            break
        case .ssmlMarksNotSupportedForTextType:
            break
        case .synthesisTaskNotFound:
            break
        case .textLengthExceeded:
            break
        case .unknown:
            return PredictionsError.unknownError("An unknown error occurred.", "")
        case .unsupportedPlsAlphabet:
            break
        case .unsupportedPlsLanguage:
            break
        default:
            return nil
        }

        return nil
    }
}
