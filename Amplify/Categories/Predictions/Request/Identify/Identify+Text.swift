//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Predictions.Identify.Request where Output == IdentifyTextResult {
    public static let text = Self(
        kind: .detectText(.lift)
    )
}
