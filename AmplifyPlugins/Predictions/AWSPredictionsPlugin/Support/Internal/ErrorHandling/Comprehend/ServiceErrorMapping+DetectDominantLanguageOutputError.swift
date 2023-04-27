//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSComprehend
import Amplify

extension ServiceErrorMapping where T == DetectDominantLanguageOutputError {
    static let detectDominantLanguage: Self = .init { error in
        switch error {
        case .internalServerException:
            return PredictionsError.service(.internalServerError)
        case .invalidRequestException:
            return PredictionsError.service(.invalidRequest)
        case .textSizeLimitExceededException:
            return PredictionsError.service(.textSizeLimitExceeded)
        case .unknown:
            return PredictionsError.unknownServiceError(error)
        }
    }
}
