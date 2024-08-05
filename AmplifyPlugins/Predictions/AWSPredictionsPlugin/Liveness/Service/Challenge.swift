//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@_spi(PredictionsFaceLiveness)
public struct Challenge: Codable {
    public let version: String
    public let type: ChallengeType
    
    public init(version: String, type: ChallengeType) {
        self.version = version
        self.type = type
    }
    
    public func queryParameterString() -> String {
        return self.type.rawValue + "_" + self.version
    }
    
    enum CodingKeys: String, CodingKey {
        case version = "Version"
        case type = "Type"
    }
}

@_spi(PredictionsFaceLiveness)
public enum ChallengeType: String, Codable {
    case faceMovementChallenge = "FaceMovementChallenge"
    case faceMovementAndLightChallenge = "FaceMovementAndLightChallenge"
}
