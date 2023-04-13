//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

enum FetchDominantLanguageEvent {

    /// Fetch dominant language event with language fetched and its score
    case completed(LanguageType, Double?)

    /// Fetch dominant langauge failed with error
    case failed(PredictionsError)
}
