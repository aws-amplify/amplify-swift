//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct ServerChallenge: Codable {
    let type: ChallengeType

    enum CodingKeys: String, CodingKey {
        case faceMovementAndLightChallenge = "FaceMovementAndLightChallenge"
        case faceMovementChallenge = "FaceMovementChallenge"
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self.type {
        case .faceMovementChallenge(let faceMovementServerChallenge):
            try container.encode(faceMovementServerChallenge, forKey: .faceMovementChallenge)
        case .faceMovementAndLightChallenge(let faceMovementAndLightServerChallenge):
            try container.encode(faceMovementAndLightServerChallenge, forKey: .faceMovementAndLightChallenge)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? container.decode(FaceMovementServerChallenge.self, forKey: .faceMovementChallenge) {
            self.type = .faceMovementChallenge(challenge: value)
        } else if let value = try? container.decode(FaceMovementAndLightServerChallenge.self, forKey: .faceMovementAndLightChallenge) {
            self.type = .faceMovementAndLightChallenge(challenge: value)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unexpected data format"
                )
            )
        }
    }
}

extension ServerChallenge {
    enum ChallengeType: Codable {
        case faceMovementChallenge(challenge: FaceMovementServerChallenge)
        case faceMovementAndLightChallenge(challenge: FaceMovementAndLightServerChallenge)
    }
}
