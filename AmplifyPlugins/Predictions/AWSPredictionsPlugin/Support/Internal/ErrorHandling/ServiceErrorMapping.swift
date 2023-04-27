//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

struct ServiceErrorMapping<T> {
    let map: (T) -> PredictionsError

    static func map<T>(_ error: T, with rule: ServiceErrorMapping<T>) -> PredictionsError {
        rule.map(error)
    }
}
