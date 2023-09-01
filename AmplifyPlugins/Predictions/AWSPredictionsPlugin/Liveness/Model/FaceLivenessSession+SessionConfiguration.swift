//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension FaceLivenessSession {
    @_spi(PredictionsFaceLiveness)
    public struct SessionConfiguration {
        public let colorChallenge: ColorChallenge
        public let ovalMatchChallenge: OvalMatchChallenge

        public init(colorChallenge: ColorChallenge, ovalMatchChallenge: OvalMatchChallenge) {
            self.colorChallenge = colorChallenge
            self.ovalMatchChallenge = ovalMatchChallenge
        }
    }
}
