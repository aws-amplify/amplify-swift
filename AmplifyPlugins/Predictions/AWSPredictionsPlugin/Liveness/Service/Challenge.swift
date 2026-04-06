//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public typealias Version = String

@_spi(PredictionsFaceLiveness)
public enum Challenge: Equatable {
    case faceMovementChallenge(Version)
    case faceMovementAndLightChallenge(Version)

    public func queryParameterString() -> String {
        switch self {
        case .faceMovementChallenge(let version):
            return "FaceMovementChallenge" + "_" + version
        case .faceMovementAndLightChallenge(let version):
            return "FaceMovementAndLightChallenge" + "_" + version
        }
    }

    public static func == (lhs: Challenge, rhs: Challenge) -> Bool {
        switch (lhs, rhs) {
        case (.faceMovementChallenge(let lhsVersion), .faceMovementChallenge(let rhsVersion)):
            return lhsVersion == rhsVersion
        case (.faceMovementAndLightChallenge(let lhsVersion), .faceMovementAndLightChallenge(let rhsVersion)):
            return lhsVersion == rhsVersion
        default:
            return false
        }
    }
}

@_spi(PredictionsFaceLiveness)
public enum ChallengeType: String, Codable {
    case faceMovementChallenge = "FaceMovementChallenge"
    case faceMovementAndLightChallenge = "FaceMovementAndLightChallenge"
}
