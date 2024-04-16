//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@_spi(PredictionsFaceLiveness)
public struct Challenge {
    public let version: String
    public let type: ChallengeType
    
    public init(version: String, type: ChallengeType) {
        self.version = version
        self.type = type
    }
    
    public func queryParameterString() -> String {
        return self.type.rawValue + "_" + self.version
    }
}

@_spi(PredictionsFaceLiveness)
public enum ChallengeType: String, Codable {
    case faceMovementChallenge = "FaceMovementChallenge"
    case faceMovementAndLightChallenge = "FaceMovementAndLightChallenge"
}
