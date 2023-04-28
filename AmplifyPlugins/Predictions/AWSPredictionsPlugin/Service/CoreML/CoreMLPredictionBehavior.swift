//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

protocol CoreMLPredictionBehavior: AnyObject {
    func comprehend(
        text: String
    ) async throws -> Predictions.Interpret.Result

    func identify<Output>(
        _ type: Predictions.Identify.Request<Output>,
        in imageURL: URL
    ) async throws -> Output

}
